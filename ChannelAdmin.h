#pragma once
#include "User.h"

class ChannelAdmin : public User
{
    Q_OBJECT
public:
    explicit ChannelAdmin(QObject* parent = nullptr) : User(parent) {}
    QString role() const override { return "channelAdmin"; }

    bool canDeleteAnyPost() const override { return true; }
    bool canManageChannel() const override { return true; }
};
