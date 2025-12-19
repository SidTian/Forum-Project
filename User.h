// User.h
#pragma once
#include <QObject>
#include <QString>
#include <QDateTime>

class User : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString userId READ userId WRITE setUserId NOTIFY userIdChanged)
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(int posts READ posts WRITE setPosts NOTIFY postsChanged)
    Q_PROPERTY(int stars READ stars WRITE setStars NOTIFY starsChanged)
    Q_PROPERTY(QDateTime lastOnline READ lastOnline NOTIFY lastOnlineChanged)
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY loggedInStateChanged)
    Q_PROPERTY(QString role READ role CONSTANT)  // 角色由子类决定

public:
    explicit User(QObject* parent = nullptr);

    // 通用 getter
    QString userId() const { return m_userId; }
    QString username() const { return m_username; }
    QString email() const { return m_email; }
    int posts() const { return m_posts; }
    int stars() const { return m_stars; }
    QDateTime lastOnline() const { return m_lastOnline; }
    bool isLoggedIn() const { return !m_userId.isEmpty(); }

    // 添加这个声明（用于更新最后在线时间并发射信号）
    void setLastOnline(const QDateTime &dt);

    // 添加这个声明（登录时设置所有属性）
    void login(const QString &id, const QString &name,
               const QString &mail = "", int posts = 0, int stars = 0);
    void logout();
    // 权限接口（不同角色实现不同）
    virtual bool canDeleteAnyPost() const { return false; }
    virtual bool canBanUser() const { return false; }
    virtual bool canManageChannel() const { return false; }

    // 纯虚函数：每个子类必须实现自己的角色名
    virtual QString role() const { return "normal"; }  // 默认普通用户

    // setter
    void setUserId(const QString& id);
    void setUsername(const QString& name);
    void setEmail(const QString& mail);
    void setPosts(int count);
    void setStars(int count);
    void updateLastOnline();  // 登录时调用

signals:
    void userIdChanged();
    void usernameChanged();
    void emailChanged();
    void postsChanged();
    void starsChanged();
    void lastOnlineChanged();
    void loggedInStateChanged();

protected:
    QString m_userId;
    QString m_username;
    QString m_email;
    int m_posts = 0;
    int m_stars = 0;
    QDateTime m_lastOnline;
};
