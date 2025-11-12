#ifndef HTTPMANAGER_H
#define HTTPMANAGER_H
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QTimer>
#include <QDebug>
#include <functional>
#include <memory>
// Interceptor base class
class Interceptor : public QObject
{
    Q_OBJECT
public:
    explicit Interceptor(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~Interceptor() = default;
    // Request interceptor - Called before sending the request
    virtual void processRequest(QNetworkRequest &request, QJsonObject &data) {
        Q_UNUSED(request)
        Q_UNUSED(data)
    }
    // Response interceptor - Called after response is received
    virtual void processResponse(QNetworkReply *reply, QJsonDocument &response) {
        Q_UNUSED(reply)
        Q_UNUSED(response)
    }
    // Error interceptor - Called when an error occurs
    virtual void processError(QNetworkReply *reply, QNetworkReply::NetworkError error) {
        Q_UNUSED(reply)
        Q_UNUSED(error)
    }
};
// Token Interceptor example
class TokenInterceptor : public Interceptor
{
    Q_OBJECT
public:
    explicit TokenInterceptor(QObject *parent = nullptr) : Interceptor(parent) {}
    void processRequest(QNetworkRequest &request, QJsonObject &data) override {
        // Retrieve token from local storage
        QString token = getStoredToken();
        if (!token.isEmpty()) {
            request.setRawHeader("Authorization", QString("Bearer %1").arg(token).toUtf8());
            qDebug() << "TokenInterceptor: Added Authorization header";
        }
    }
private:
    QString getStoredToken() {
        // Here should retrieve token from QSettings or other storage
        return m_token;
    }
public:
    void setToken(const QString &token) { m_token = token; }
private:
    QString m_token;
};
// Logging Interceptor example
class LoggingInterceptor : public Interceptor
{
    Q_OBJECT
public:
    explicit LoggingInterceptor(QObject *parent = nullptr) : Interceptor(parent) {}
    void processRequest(QNetworkRequest &request, QJsonObject &data) override {
        qDebug() << "[HTTP REQUEST]" << request.url().toString();
        if (!data.isEmpty()) {
            qDebug() << "[REQUEST DATA]" << QJsonDocument(data).toJson(QJsonDocument::Compact);
        }
    }
    void processResponse(QNetworkReply *reply, QJsonDocument &response) override {
        qDebug() << "[HTTP RESPONSE]" << reply->url().toString()
        << "Status:" << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (!response.isEmpty()) {
            qDebug() << "[RESPONSE DATA]" << response.toJson(QJsonDocument::Compact);
        }
    }
    void processError(QNetworkReply *reply, QNetworkReply::NetworkError error) override {
        qDebug() << "[HTTP ERROR]" << reply->url().toString()
        << "Error:" << error << reply->errorString();
    }
};
// Main HTTP Manager class
class HttpManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
    Q_PROPERTY(int timeout READ timeout WRITE setTimeout NOTIFY timeoutChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
public:
    explicit HttpManager(QObject *parent = nullptr);
    ~HttpManager();
    // Basic configuration
    QString baseUrl() const { return m_baseUrl; }
    void setBaseUrl(const QString &url);
    int timeout() const { return m_timeout; }
    void setTimeout(int ms);
    bool isLoading() const { return m_activeRequests > 0; }
    // Interceptor management
    void addRequestInterceptor(Interceptor *interceptor);
    void addResponseInterceptor(Interceptor *interceptor);
    void removeInterceptor(Interceptor *interceptor);
    void clearInterceptors();
    // Convenience method: Set authentication token
    Q_INVOKABLE void setAuthToken(const QString &token);
    Q_INVOKABLE void clearAuthToken();
    // HTTP methods - For QML invocation
    Q_INVOKABLE void get(const QString &endpoint,
                         const QVariantMap &params = QVariantMap());
    Q_INVOKABLE void post(const QString &endpoint,
                          const QVariantMap &data = QVariantMap());
    Q_INVOKABLE void put(const QString &endpoint,
                         const QVariantMap &data = QVariantMap());
    Q_INVOKABLE void deleteResource(const QString &endpoint);
    // Login method for QML (compatible with your existing code)
    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void register_(const QString &username, const QString &password,
                               const QString &email);
    // Forum-related API methods
    Q_INVOKABLE void getChannels();
    Q_INVOKABLE void getPosts(int channelId);
    Q_INVOKABLE void getPostDetails(int postId);
    Q_INVOKABLE void createPost(const QString &title, const QString &content, int channelId);
    Q_INVOKABLE void createReply(int postId, const QString &content, int parentReplyId = -1);
    Q_INVOKABLE void getUserDetails(const QString &userId);
    // Admin operations
    Q_INVOKABLE void lockPost(int postId, bool locked);
    Q_INVOKABLE void deletePost(int postId);
    Q_INVOKABLE void deleteReply(int replyId);
signals:
    // Property change signals
    void baseUrlChanged();
    void timeoutChanged();
    void isLoadingChanged();
    // General response signals
    void requestSuccess(const QString &endpoint, const QJsonDocument &response);
    void requestError(const QString &endpoint, const QString &error, int statusCode);
    // Response signals for specific operations (compatible with your existing QML code)
    void loginResponse(const QJsonObject &response, bool success, const QString &message);
    void registerResponse(const QJsonObject &response, bool success, const QString &message);
    void channelsLoaded(const QJsonArray &channels);
    void postsLoaded(const QJsonArray &posts);
    void postDetailsLoaded(const QJsonObject &post);
    void postCreated(bool success, const QString &message);
    void replyCreated(bool success, const QString &message);
    void userDetailsLoaded(const QJsonObject &user);
private slots:
    void handleResponse();
    void handleError(QNetworkReply::NetworkError error);
    void handleTimeout();
private:
    // Declaration: Handle specific endpoint responses (signature must match .cpp exactly)
    void handleSpecificResponse(const QString &endpoint,
                                const QJsonDocument &response,
                                int statusCode);
private:
    // Internal request methods
    void sendRequest(const QString &method,
                     const QString &endpoint,
                     const QJsonObject &data = QJsonObject(),
                     const QVariantMap &params = QVariantMap());
    QUrl buildUrl(const QString &endpoint, const QVariantMap &params = QVariantMap()) const;
    // Execute interceptors
    void executeRequestInterceptors(QNetworkRequest &request, QJsonObject &data);
    void executeResponseInterceptors(QNetworkReply *reply, QJsonDocument &response);
    void executeErrorInterceptors(QNetworkReply *reply, QNetworkReply::NetworkError error);
private:
    QNetworkAccessManager *m_networkManager;
    QString m_baseUrl;
    int m_timeout;
    int m_activeRequests;
    // Interceptor lists
    QList<Interceptor*> m_requestInterceptors;
    QList<Interceptor*> m_responseInterceptors;
    // Built-in interceptors
    TokenInterceptor *m_tokenInterceptor;
    LoggingInterceptor *m_loggingInterceptor;
    // Request timeout management
    QHash<QNetworkReply*, QTimer*> m_timeoutTimers;
};
#endif // HTTPMANAGER_H
