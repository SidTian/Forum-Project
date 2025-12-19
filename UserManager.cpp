// UserManager.cpp
#include "UserManager.h"
#include <QDateTime>

UserManager* UserManager::m_instance = nullptr;

UserManager* UserManager::instance()
{
    if (!m_instance)
        m_instance = new UserManager();
    return m_instance;
}

UserManager::UserManager(QObject* parent) : QObject(parent)
{
    // not login state
    m_factory = new NormalUserFactory();
    m_currentUser = m_factory->createUser(this);
}

UserManager::~UserManager()
{
    delete m_currentUser;
    delete m_factory;
}

void UserManager::login(const QString& id, const QString& name,
                        const QString& email, int posts, int stars,
                        const QString& role)
{
    // choose factory based on role
    delete m_factory;
    if (role == "admin")
        m_factory = new AdminFactory();
    else if (role == "channelAdmin")
        m_factory = new ChannelAdminFactory();
    else
        m_factory = new NormalUserFactory();

    // create new user
    delete m_currentUser;
    m_currentUser = m_factory->createUser(this);

    // set property
    m_currentUser->setUserId(id);
    m_currentUser->setUsername(name);
    m_currentUser->setEmail(email);
    m_currentUser->setPosts(posts);
    m_currentUser->setStars(stars);
    m_currentUser->updateLastOnline();

    emit currentUserChanged();
}

void UserManager::logout()
{
    delete m_currentUser;
    delete m_factory;

    m_factory = new NormalUserFactory();
    m_currentUser = m_factory->createUser(this);
    emit currentUserChanged();
}
