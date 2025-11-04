#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>

class LoginManager : public QObject
{
    Q_OBJECT

public:
    explicit LoginManager(QObject *parent = nullptr);

    Q_INVOKABLE void login(const QString &username, const QString &password);  // QML 可调用

signals:
    void loginSuccess(const QString &username, const QString &message);  // 登录成功信号
    void loginError(const QString &errorMessage);  // 登录失败信号

private slots:
    void onLoginReplyFinished();  // 处理响应

private:
    QNetworkAccessManager *m_networkManager;
    QNetworkReply *m_currentReply;
    QString m_username;  // 新增：临时存储用户名
};

#endif // LOGINMANAGER_H
