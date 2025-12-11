// UserManager.cpp
#include "UserManager.h"

UserManager* UserManager::m_instance = nullptr;

UserManager* UserManager::instance()
{
    if (!m_instance)
        m_instance = new UserManager();
    return m_instance;
}

void UserManager::registerQmlTypes()
{
    // qmlRegisterSingletonInstance("Forum", 1, 0, "User", UserManager::instance());
    // 也可以直接用 contextProperty，下面 main.cpp 演示两种方式都行
}

UserManager::UserManager(QObject *parent)
    : QObject(parent)
{
    m_currentUser = new User(this);
}

UserManager::~UserManager()
{
    // 单例一般不删，但 Qt 退出时会自动清理
}
