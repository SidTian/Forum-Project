#include "LoginManager.h"
#include <QUrl>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

LoginManager::LoginManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
{
}

void LoginManager::login(const QString &username, const QString &password)
{
    m_username = username;  // 新增：存储用户名

    if (m_currentReply) {
        m_currentReply->deleteLater();  // 取消上一个请求
    }

    QUrl apiUrl("http://34.66.169.26:3000/login");
    QNetworkRequest request(apiUrl);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    // 构建 JSON 请求体
    QJsonObject jsonData;
    jsonData["username"] = username;
    jsonData["password"] = password;
    QJsonDocument doc(jsonData);
    QByteArray data = doc.toJson();

    m_currentReply = m_networkManager->post(request, data);
    connect(m_currentReply, &QNetworkReply::finished, this, &LoginManager::onLoginReplyFinished);
}

void LoginManager::onLoginReplyFinished()
{
    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "Network error:" << m_currentReply->errorString();
        emit loginError("Network error: " + m_currentReply->errorString());
        m_currentReply->deleteLater();
        return;
    }

    // 解析 JSON 响应
    QJsonDocument doc = QJsonDocument::fromJson(m_currentReply->readAll());
    if (doc.isObject()) {
        QJsonObject responseObj = doc.object();
        int code = responseObj["code"].toInt();
        QString message = responseObj["message"].toString();
        QString username = responseObj["username"].toString();
        if (code == 1) {
            emit loginSuccess(username, message);
        } else {
            emit loginError(message);
        }
    } else {
        qWarning() << "Invalid JSON response";
        emit loginError("Invalid response format");
    }

    m_currentReply->deleteLater();
}
