// UserManager.h
#pragma once
#include <QObject>
#include "User.h"
#include "UserFactory.h"

class UserManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(User* currentUser READ currentUser NOTIFY currentUserChanged)

public:
    static UserManager* instance();

    User* currentUser() const { return m_currentUser; }

    Q_INVOKABLE void login(const QString& id, const QString& name,
                           const QString& email, int posts, int stars,
                           const QString& role);

    Q_INVOKABLE void logout();

signals:
    void currentUserChanged();

private:
    explicit UserManager(QObject* parent = nullptr);
    ~UserManager();

    static UserManager* m_instance;
    User* m_currentUser = nullptr;
    UserFactory* m_factory = nullptr;
};
