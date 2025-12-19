// UserFactory.h
#pragma once
#include "User.h"
#include "NormalUser.h"
#include "ChannelAdmin.h"
#include "Admin.h"

class UserFactory
{
public:
    virtual ~UserFactory() = default;
    virtual User* createUser(QObject* parent = nullptr) = 0;  // Factory Method
};

class NormalUserFactory : public UserFactory
{
public:
    User* createUser(QObject* parent = nullptr) override {
        return new NormalUser(parent);
    }
};

class ChannelAdminFactory : public UserFactory
{
public:
    User* createUser(QObject* parent = nullptr) override {
        return new ChannelAdmin(parent);
    }
};

class AdminFactory : public UserFactory
{
public:
    User* createUser(QObject* parent = nullptr) override {
        return new Admin(parent);
    }
};
