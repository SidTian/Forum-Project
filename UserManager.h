// UserManager.h
#pragma once
#include <QObject>
#include "User.h"

class UserManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(User* currentUser READ currentUser CONSTANT)   // QML 直接用 User.username

public:
    static UserManager* instance();
    static void registerQmlTypes();   // 在 main.cpp 调用一次即可

    User* currentUser() const { return m_currentUser; }

    // 方便 QML 直接调用登录/登出
    Q_INVOKABLE void login(const QString &id, const QString &name,
                           const QString &mail = "", int posts = 0, int stars = 0)
    {
        m_currentUser->login(id, name, mail, posts, stars);
    }

    Q_INVOKABLE void logout()
    {
        m_currentUser->logout();
    }

private:
    explicit UserManager(QObject *parent = nullptr);
    ~UserManager();

    static UserManager *m_instance;
    User *m_currentUser;
};
