// NormalUser.h
#pragma once
#include "User.h"

class NormalUser : public User
{
    Q_OBJECT
public:
    explicit NormalUser(QObject* parent = nullptr) : User(parent) {}  // inline 实现
    QString role() const override { return "normal"; }

    bool canDeleteAnyPost() const override { return false; }
};
