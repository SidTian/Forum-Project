#pragma once
#include "User.h"

class ChannelAdmin : public User
{
    Q_OBJECT
public:
    explicit ChannelAdmin(QObject* parent = nullptr) : User(parent) {}
    QString role() const override { return "channelAdmin"; }

    bool canDeleteAnyPost() const override { return true; }     // 可以删频道内任意帖
    bool canManageChannel() const override { return true; }     // 可以管理频道
};
