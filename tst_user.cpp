// tst_user.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "User.h"
#include "UserManager.h"
#include "NormalUser.h"
#include "ChannelAdmin.h"
#include "Admin.h"
#include <QSignalSpy>
#include <QDateTime>

using ::testing::_;

// ====================== User class general test ======================

TEST(UserTest, InitialState) {
    User user;

    EXPECT_EQ(user.userId(), QString());
    EXPECT_EQ(user.username(), QString());
    EXPECT_EQ(user.email(), QString());
    EXPECT_EQ(user.posts(), 0);
    EXPECT_EQ(user.stars(), 0);
    EXPECT_FALSE(user.isLoggedIn());
    EXPECT_FALSE(user.lastOnline().isNull());
}

TEST(UserTest, LoginUpdatesPropertiesAndEmitsSignals) {
    User user;

    QSignalSpy idSpy(&user, &User::userIdChanged);
    QSignalSpy nameSpy(&user, &User::usernameChanged);
    QSignalSpy emailSpy(&user, &User::emailChanged);
    QSignalSpy postsSpy(&user, &User::postsChanged);
    QSignalSpy starsSpy(&user, &User::starsChanged);
    QSignalSpy lastOnlineSpy(&user, &User::lastOnlineChanged);
    QSignalSpy loggedInSpy(&user, &User::loggedInStateChanged);

    user.login("1001", "SidTian", "sid@example.com", 42, 999);

    EXPECT_EQ(user.userId(), "1001");
    EXPECT_EQ(user.username(), "SidTian");
    EXPECT_EQ(user.email(), "sid@example.com");
    EXPECT_EQ(user.posts(), 42);
    EXPECT_EQ(user.stars(), 999);
    EXPECT_TRUE(user.isLoggedIn());

    EXPECT_EQ(idSpy.count(), 1);
    EXPECT_EQ(nameSpy.count(), 1);
    EXPECT_EQ(emailSpy.count(), 1);
    EXPECT_EQ(postsSpy.count(), 1);
    EXPECT_EQ(starsSpy.count(), 1);
    EXPECT_EQ(lastOnlineSpy.count(), 1);
    EXPECT_EQ(loggedInSpy.count(), 1);
}

TEST(UserTest, LogoutResetsToEmpty) {
    User user;
    user.login("888", "Admin", "", 100, 1000);
    user.logout();

    EXPECT_EQ(user.userId(), QString());
    EXPECT_EQ(user.username(), QString());
    EXPECT_EQ(user.email(), QString());
    EXPECT_EQ(user.posts(), 0);
    EXPECT_EQ(user.stars(), 0);
    EXPECT_FALSE(user.isLoggedIn());
}

// ====================== detailed user class (Factory Method verify） ======================

TEST(UserTypeTest, NormalUserHasCorrectRoleAndPermissions) {
    NormalUser user;

    EXPECT_EQ(user.role(), "normal");
    EXPECT_FALSE(user.canDeleteAnyPost());
    EXPECT_FALSE(user.canBanUser());
    EXPECT_FALSE(user.canManageChannel());
}

TEST(UserTypeTest, ChannelAdminHasCorrectRoleAndPermissions) {
    ChannelAdmin user;

    EXPECT_EQ(user.role(), "channelAdmin");
    EXPECT_TRUE(user.canDeleteAnyPost());
    EXPECT_FALSE(user.canBanUser());
    EXPECT_TRUE(user.canManageChannel());
}

TEST(UserTypeTest, AdminHasFullPermissions) {
    Admin user;

    EXPECT_EQ(user.role(), "admin");
    EXPECT_TRUE(user.canDeleteAnyPost());
    EXPECT_TRUE(user.canBanUser());
    EXPECT_TRUE(user.canManageChannel());
}

// ====================== UserManager + Factory Method test ======================

TEST(UserManagerTest, SingletonReturnsSameInstance) {
    UserManager* inst1 = UserManager::instance();
    UserManager* inst2 = UserManager::instance();

    EXPECT_EQ(inst1, inst2);
    EXPECT_NE(inst1, nullptr);
}

TEST(UserManagerTest, LoginAsNormalUserCreatesNormalUser) {
    UserManager* manager = UserManager::instance();

    manager->login("1", "Alice", "alice@example.com", 10, 50, "normal");

    User* current = manager->currentUser();
    ASSERT_NE(current, nullptr);

    // dynamic check type
    NormalUser* normal = dynamic_cast<NormalUser*>(current);
    ASSERT_NE(normal, nullptr);  // NormalUser type

    EXPECT_EQ(current->role(), "normal");
    EXPECT_FALSE(current->canBanUser());
}

TEST(UserManagerTest, LoginAsChannelAdminCreatesChannelAdmin) {
    UserManager* manager = UserManager::instance();

    manager->login("2", "Bob", "", 20, 100, "channelAdmin");

    User* current = manager->currentUser();
    ChannelAdmin* admin = dynamic_cast<ChannelAdmin*>(current);
    ASSERT_NE(admin, nullptr);

    EXPECT_EQ(current->role(), "channelAdmin");
    EXPECT_TRUE(current->canManageChannel());
    EXPECT_FALSE(current->canBanUser());
}

TEST(UserManagerTest, LoginAsAdminCreatesAdmin) {
    UserManager* manager = UserManager::instance();

    manager->login("3", "Charlie", "", 30, 500, "admin");

    User* current = manager->currentUser();
    Admin* admin = dynamic_cast<Admin*>(current);
    ASSERT_NE(admin, nullptr);

    EXPECT_EQ(current->role(), "admin");
    EXPECT_TRUE(current->canBanUser());
    EXPECT_TRUE(current->canDeleteAnyPost());
    EXPECT_TRUE(current->canManageChannel());
}

TEST(UserManagerTest, CurrentUserChangedSignalEmittedOnLogin) {
    UserManager* manager = UserManager::instance();

    QSignalSpy spy(manager, &UserManager::currentUserChanged);

    manager->login("999", "TestUser", "", 0, 0, "normal");

    EXPECT_GE(spy.count(), 1);
}

TEST(UserManagerTest, MultipleRoleSwitchesWorkCorrectly) {
    UserManager* manager = UserManager::instance();

    manager->login("A", "UserA", "", 1, 1, "normal");
    EXPECT_EQ(manager->currentUser()->role(), "normal");

    manager->login("B", "UserB", "", 2, 2, "channelAdmin");
    EXPECT_EQ(manager->currentUser()->role(), "channelAdmin");

    manager->login("C", "UserC", "", 3, 3, "admin");
    EXPECT_EQ(manager->currentUser()->role(), "admin");

    manager->logout();
    EXPECT_EQ(manager->currentUser()->role(), "normal");  // return normal
}
