// User.cpp
#include "User.h"
#include <QDateTime>

User::User(QObject *parent) : QObject(parent)
{
    m_lastOnline = QDateTime::currentDateTime();
}

void User::setUserId(const QString &id)
{
    if (m_userId != id) {
        m_userId = id;
        emit userIdChanged();
        emit loggedInStateChanged();
    }
}

void User::setUsername(const QString &name)
{
    if (m_username != name) {
        m_username = name;
        emit usernameChanged();
    }
}

void User::setEmail(const QString &mail)
{
    if (m_email != mail) {
        m_email = mail;
        emit emailChanged();
    }
}

void User::setPosts(int count)
{
    if (m_posts != count) {
        m_posts = count;
        emit postsChanged();
    }
}

void User::setStars(int count)
{
    if (m_stars != count) {
        m_stars = count;
        emit starsChanged();
    }
}

void User::setLastOnline(const QDateTime &dt)
{
    if (m_lastOnline != dt) {
        m_lastOnline = dt;
        emit lastOnlineChanged();
    }
}

void User::login(const QString &id, const QString &name, const QString &mail, int posts, int stars)
{
    setUserId(id);
    setUsername(name);
    setEmail(mail);
    setPosts(posts);
    setStars(stars);
    setLastOnline(QDateTime::currentDateTime());
}

void User::logout()
{
    setUserId("");
    setUsername("游客");
    setEmail("");
    setPosts(0);
    setStars(0);
    setLastOnline(QDateTime::currentDateTime());
}
