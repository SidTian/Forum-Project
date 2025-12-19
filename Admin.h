#pragma once
#include "User.h"

class Admin : public User
{
    Q_OBJECT
public:
    explicit Admin(QObject* parent = nullptr) : User(parent) {}
    QString role() const override { return "admin"; }

    bool canDeleteAnyPost() const override { return true; }
    bool canBanUser() const override { return true; }
    bool canManageChannel() const override { return true; }
};
