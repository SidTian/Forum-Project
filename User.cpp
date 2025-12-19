// User.cpp
#include "User.h"
#include <QDateTime>

// Constructor: Initialize last online time
User::User(QObject *parent) : QObject(parent)
{
    m_lastOnline = QDateTime::currentDateTime();
}

// Set user ID and emit signals if changed
void User::setUserId(const QString &id)
{
    if (m_userId != id) {
        m_userId = id;
        emit userIdChanged();
        emit loggedInStateChanged();
    }
}

// Set username and emit signal if changed
void User::setUsername(const QString &name)
{
    if (m_username != name) {
        m_username = name;
        emit usernameChanged();
    }
}

// Set email and emit signal if changed
void User::setEmail(const QString &mail)
{
    if (m_email != mail) {
        m_email = mail;
        emit emailChanged();
    }
}

// Set post count and emit signal if changed
void User::setPosts(int count)
{
    if (m_posts != count) {
        m_posts = count;
        emit postsChanged();
    }
}

// Set star count and emit signal if changed
void User::setStars(int count)
{
    if (m_stars != count) {
        m_stars = count;
        emit starsChanged();
    }
}

// Set last online time and emit signal if changed
void User::setLastOnline(const QDateTime &dt)
{
    if (m_lastOnline != dt) {
        m_lastOnline = dt;
        emit lastOnlineChanged();
    }
}

// Perform login: update all user info and ensure lastOnline signal is emitted
void User::login(const QString &id, const QString &name, const QString &mail, int posts, int stars)
{
    setUserId(id);
    setUsername(name);
    setEmail(mail);
    setPosts(posts);
    setStars(stars);

    // Force update last online time and emit signal (login means user is active)
    m_lastOnline = QDateTime::currentDateTime();
    emit lastOnlineChanged();
}

void User::updateLastOnline()
{
    m_lastOnline = QDateTime::currentDateTime();
    emit lastOnlineChanged();
}

// Perform logout: reset to guest state
void User::logout()
{
    setUserId("");
    setUsername("");
    setEmail("");
    setPosts(0);
    setStars(0);
    setLastOnline(QDateTime::currentDateTime());
}
