// User.h
#pragma once
#include <QObject>
#include <QString>
#include <QDateTime>

class User : public QObject
{
    Q_OBJECT

    // 这些属性 QML 可以直接读取
    Q_PROPERTY(QString userId      READ userId      WRITE setUserId      NOTIFY userIdChanged)
    Q_PROPERTY(QString username    READ username    WRITE setUsername    NOTIFY usernameChanged)
    Q_PROPERTY(QString email       READ email       WRITE setEmail       NOTIFY emailChanged)
    Q_PROPERTY(int posts           READ posts       WRITE setPosts       NOTIFY postsChanged)
    Q_PROPERTY(int stars           READ stars       WRITE setStars       NOTIFY starsChanged)
    Q_PROPERTY(QDateTime lastOnline READ lastOnline WRITE setLastOnline NOTIFY lastOnlineChanged)
    Q_PROPERTY(bool isLoggedIn     READ isLoggedIn                       NOTIFY loggedInStateChanged)

public:
    explicit User(QObject *parent = nullptr);

    // Getter
    QString userId() const { return m_userId; }
    QString username() const { return m_username; }
    QString email() const { return m_email; }
    int posts() const { return m_posts; }
    int stars() const { return m_stars; }
    QDateTime lastOnline() const { return m_lastOnline; }
    bool isLoggedIn() const { return !m_userId.isEmpty(); }

    // Setter（会自动通知 QML 刷新）
    void setUserId(const QString &id);
    void setUsername(const QString &name);
    void setEmail(const QString &mail);
    void setPosts(int count);
    void setStars(int count);
    void setLastOnline(const QDateTime &dt);

    // 方便的登录/登出
    void login(const QString &id, const QString &name, const QString &mail = "", int posts = 0, int stars = 0);
    void logout();

signals:
    void userIdChanged();
    void usernameChanged();
    void emailChanged();
    void postsChanged();
    void starsChanged();
    void lastOnlineChanged();
    void loggedInStateChanged();   // 登录状态变化

private:
    QString m_userId;
    QString m_username = "游客";
    QString m_email;
    int m_posts = 0;
    int m_stars = 0;
    QDateTime m_lastOnline;
};
