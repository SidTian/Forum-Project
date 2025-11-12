#include "httpmanager.h"
#include <QUrlQuery>
#include <QSettings>
HttpManager::HttpManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_baseUrl("http://sidtian.com:3000")
    , m_timeout(30000) // Default 30 seconds timeout
    , m_activeRequests(0)
{
    // Create built-in interceptors
    m_tokenInterceptor = new TokenInterceptor(this);
    m_loggingInterceptor = new LoggingInterceptor(this);
    // Add logging interceptor by default
    addRequestInterceptor(m_loggingInterceptor);
    addResponseInterceptor(m_loggingInterceptor);
}
HttpManager::~HttpManager()
{
    // Clean up timeout timers
    for (auto timer : m_timeoutTimers.values()) {
        timer->stop();
        timer->deleteLater();
    }
}
void HttpManager::setBaseUrl(const QString &url)
{
    if (m_baseUrl != url) {
        m_baseUrl = url;
        emit baseUrlChanged();
    }
}
void HttpManager::setTimeout(int ms)
{
    if (m_timeout != ms) {
        m_timeout = ms;
        emit timeoutChanged();
    }
}
void HttpManager::addRequestInterceptor(Interceptor *interceptor)
{
    if (interceptor && !m_requestInterceptors.contains(interceptor)) {
        m_requestInterceptors.append(interceptor);
    }
}
void HttpManager::addResponseInterceptor(Interceptor *interceptor)
{
    if (interceptor && !m_responseInterceptors.contains(interceptor)) {
        m_responseInterceptors.append(interceptor);
    }
}
void HttpManager::removeInterceptor(Interceptor *interceptor)
{
    m_requestInterceptors.removeAll(interceptor);
    m_responseInterceptors.removeAll(interceptor);
}
void HttpManager::clearInterceptors()
{
    m_requestInterceptors.clear();
    m_responseInterceptors.clear();
    // Re-add built-in interceptors
    addRequestInterceptor(m_loggingInterceptor);
    addResponseInterceptor(m_loggingInterceptor);
}
void HttpManager::setAuthToken(const QString &token)
{
    m_tokenInterceptor->setToken(token);
    // If the token interceptor has not been added yet, add it
    if (!m_requestInterceptors.contains(m_tokenInterceptor)) {
        addRequestInterceptor(m_tokenInterceptor);
    }
    // Optional: Save to QSettings
    QSettings settings;
    settings.setValue("auth/token", token);
}
void HttpManager::clearAuthToken()
{
    m_tokenInterceptor->setToken("");
    removeInterceptor(m_tokenInterceptor);
    QSettings settings;
    settings.remove("auth/token");
}
QUrl HttpManager::buildUrl(const QString &endpoint, const QVariantMap &params) const
{
    QUrl url(m_baseUrl + endpoint);
    if (!params.isEmpty()) {
        QUrlQuery query;
        for (auto it = params.begin(); it != params.end(); ++it) {
            query.addQueryItem(it.key(), it.value().toString());
        }
        url.setQuery(query);
    }
    return url;
}
void HttpManager::executeRequestInterceptors(QNetworkRequest &request, QJsonObject &data)
{
    for (Interceptor *interceptor : m_requestInterceptors) {
        interceptor->processRequest(request, data);
    }
}
void HttpManager::executeResponseInterceptors(QNetworkReply *reply, QJsonDocument &response)
{
    for (Interceptor *interceptor : m_responseInterceptors) {
        interceptor->processResponse(reply, response);
    }
}
void HttpManager::executeErrorInterceptors(QNetworkReply *reply, QNetworkReply::NetworkError error)
{
    for (Interceptor *interceptor : m_responseInterceptors) {
        interceptor->processError(reply, error);
    }
}
void HttpManager::sendRequest(const QString &method,
                              const QString &endpoint,
                              const QJsonObject &data,
                              const QVariantMap &params)
{
    // Debug output: Confirm that the request has been called
    qDebug() << "[HTTP] Sending request to" << endpoint
             << "with method" << method
             << "and params" << params;
    QUrl url = buildUrl(endpoint, params);
    QNetworkRequest request(url);
    // Set default headers
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("Accept", "application/json");
    // Copy data so that interceptors can modify it
    QJsonObject requestData = data;
    // Execute request interceptors
    executeRequestInterceptors(request, requestData);
    // Send request
    QNetworkReply *reply = nullptr;
    if (method == "GET") {
        reply = m_networkManager->get(request);
    } else if (method == "POST") {
        QJsonDocument doc(requestData);
        reply = m_networkManager->post(request, doc.toJson());
    } else if (method == "PUT") {
        QJsonDocument doc(requestData);
        reply = m_networkManager->put(request, doc.toJson());
    } else if (method == "DELETE") {
        reply = m_networkManager->deleteResource(request);
    }
    if (!reply) {
        qWarning() << "Failed to create network request for method:" << method;
        return;
    }
    // Increment active request count
    m_activeRequests++;
    emit isLoadingChanged();
    // Set timeout timer
    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(m_timeout);
    connect(timer, &QTimer::timeout, [this, reply]() {
        reply->abort();
        handleTimeout();
    });
    timer->start();
    m_timeoutTimers[reply] = timer;
    // Connect response signals
    connect(reply, &QNetworkReply::finished, this, &HttpManager::handleResponse);
    connect(reply, &QNetworkReply::errorOccurred, this, &HttpManager::handleError);
    // Save endpoint information to reply
    reply->setProperty("endpoint", endpoint);
    reply->setProperty("method", method);
}
void HttpManager::handleResponse()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    // Stop and delete timeout timer
    if (m_timeoutTimers.contains(reply)) {
        m_timeoutTimers[reply]->stop();
        m_timeoutTimers[reply]->deleteLater();
        m_timeoutTimers.remove(reply);
    }
    // Decrement active request count
    m_activeRequests--;
    emit isLoadingChanged();
    QString endpoint = reply->property("endpoint").toString();
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        QJsonDocument response = QJsonDocument::fromJson(responseData);
        // Execute response interceptors
        executeResponseInterceptors(reply, response);
        // Emit general success signal
        emit requestSuccess(endpoint, response);
        // Handle specific endpoint response
        handleSpecificResponse(endpoint, response, statusCode);
    }
    reply->deleteLater();
}
void HttpManager::handleError(QNetworkReply::NetworkError error)
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QString endpoint = reply->property("endpoint").toString();
    QString errorString = reply->errorString();
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    // Execute error interceptors
    executeErrorInterceptors(reply, error);
    // Emit error signal
    emit requestError(endpoint, errorString, statusCode);
    // Specific error handling
    if (endpoint.contains("/login")) {
        emit loginResponse(QJsonObject(), false, errorString);
    } else if (endpoint.contains("/register")) {
        emit registerResponse(QJsonObject(), false, errorString);
    }
}
void HttpManager::handleTimeout()
{
    emit requestError("", "Request timeout", 0);
}
// Handle specific endpoint responses
void HttpManager::handleSpecificResponse(const QString &endpoint,
                                         const QJsonDocument &response,
                                         int statusCode)
{
    QJsonObject obj = response.object();
    if (endpoint.contains("/login")) {
        bool success = obj["code"].toInt() == 1;
        QString message = obj["message"].toString();
        emit loginResponse(obj, success, message);
        // If login successful, automatically save token
        if (success && obj.contains("token")) {
            setAuthToken(obj["token"].toString());
        }
    }
    else if (endpoint.contains("/register")) {
        bool success = obj["code"].toInt() == 1;
        QString message = obj["message"].toString();
        emit registerResponse(obj, success, message);
    }
    else if (endpoint.contains("/channels")) {
        emit channelsLoaded(response.array());
    }
    else if (endpoint.contains("/posts") && !endpoint.contains("/details")) {
        emit postsLoaded(response.array());
    }
    else if (endpoint.contains("/posts/details")) {
        emit postDetailsLoaded(obj);
    }
    else if (endpoint.contains("/posts/create")) {
        bool success = obj["code"].toInt() == 1;
        QString message = obj["message"].toString();
        emit postCreated(success, message);
    }
    else if (endpoint.contains("/reply")) {
        bool success = obj["code"].toInt() == 1;
        QString message = obj["message"].toString();
        emit replyCreated(success, message);
    }
    else if (endpoint.contains("/user")) {
        emit userDetailsLoaded(obj);
    }
}
// HTTP method implementations
void HttpManager::get(const QString &endpoint, const QVariantMap &params)
{
    sendRequest("GET", endpoint, QJsonObject(), params);
}
void HttpManager::post(const QString &endpoint, const QVariantMap &data)
{
    QJsonObject jsonData = QJsonObject::fromVariantMap(data);
    sendRequest("POST", endpoint, jsonData);
}
void HttpManager::put(const QString &endpoint, const QVariantMap &data)
{
    QJsonObject jsonData = QJsonObject::fromVariantMap(data);
    sendRequest("PUT", endpoint, jsonData);
}
void HttpManager::deleteResource(const QString &endpoint)
{
    sendRequest("DELETE", endpoint);
}
// Forum API method implementations
void HttpManager::login(const QString &username, const QString &password)
{
    QJsonObject data;
    data["username"] = username;
    data["password"] = password;
    sendRequest("POST", "/login", data);
}
void HttpManager::register_(const QString &username, const QString &password, const QString &email)
{
    QJsonObject data;
    data["username"] = username;
    data["password"] = password;
    data["email"] = email;
    sendRequest("POST", "/register", data);
}
void HttpManager::getChannels()
{
    sendRequest("GET", "/channels");
}
void HttpManager::getPosts(int channelId)
{
    QVariantMap params;
    params["channelId"] = channelId;
    sendRequest("GET", "/posts", QJsonObject(), params);
}
void HttpManager::getPostDetails(int postId)
{
    sendRequest("GET", QString("/posts/details/%1").arg(postId));
}
void HttpManager::createPost(const QString &title, const QString &content, int channelId)
{
    QJsonObject data;
    data["title"] = title;
    data["content"] = content;
    data["channelId"] = channelId;
    sendRequest("POST", "/posts/create", data);
}
void HttpManager::createReply(int postId, const QString &content, int parentReplyId)
{
    QJsonObject data;
    data["postId"] = postId;
    data["content"] = content;
    if (parentReplyId >= 0) {
        data["parentReplyId"] = parentReplyId;
    }
    sendRequest("POST", "/reply", data);
}
void HttpManager::getUserDetails(const QString &userId)
{
    sendRequest("GET", QString("/user/%1").arg(userId));
}
void HttpManager::lockPost(int postId, bool locked)
{
    QJsonObject data;
    data["locked"] = locked;
    sendRequest("PUT", QString("/posts/%1/lock").arg(postId), data);
}
void HttpManager::deletePost(int postId)
{
    sendRequest("DELETE", QString("/posts/%1").arg(postId));
}
void HttpManager::deleteReply(int replyId)
{
    sendRequest("DELETE", QString("/reply/%1").arg(replyId));
}
