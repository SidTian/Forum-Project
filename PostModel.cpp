#include "PostModel.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

PostModel::PostModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_networkManager = new QNetworkAccessManager(this);
    m_currentReply = nullptr;

    // 发起 GET 请求
    QUrl apiUrl("http://34.66.169.26:3000/get_forum_data");
    QNetworkRequest request(apiUrl);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    m_currentReply = m_networkManager->get(request);
    connect(m_currentReply, &QNetworkReply::finished, this, &PostModel::onNetworkReplyFinished);
}

void PostModel::onNetworkReplyFinished()
{
    if (m_currentReply->error() != QNetworkReply::NoError) {
        qWarning() << "Network error:" << m_currentReply->errorString();
        // 回退到静态数据
        m_posts.clear();
        m_posts.append({
            {"Forum Rules Update and Guidelines", "Admin", "We've updated the forum rules...", QDateTime::fromString("2025-09-17 10:00", "yyyy-MM-dd hh:mm"), 10, 5}
        });
        m_posts.append({
            {"Qt is Awesome", "User1", "Let's discuss Qt development!", QDateTime::fromString("2025-09-13 14:00", "yyyy-MM-dd hh:mm"), 8, 3}
        });
        beginResetModel();
        endResetModel();
        qDebug() << "Fallback to static data:" << m_posts.size() << "posts";
        m_currentReply->deleteLater();
        return;
    }

    // 解析 JSON
    QJsonDocument doc = QJsonDocument::fromJson(m_currentReply->readAll());
    if (doc.isArray()) {
        QJsonArray postsArray = doc.array();
        m_posts.clear();
        for (const QJsonValue &value : postsArray) {
            if (value.isObject()) {
                QJsonObject postObj = value.toObject();
                QString timestampStr = postObj["timestamp"].toString();
                QDateTime timestamp = QDateTime::fromString(timestampStr, "yyyy-MM-dd hh:mm");
                m_posts.append({
                    postObj["title"].toString(),
                    postObj["author"].toString(),
                    postObj["content"].toString(),
                    timestamp,
                    postObj["star"].toInt(),
                    postObj["comments"].toInt()
                });
            }
        }
        beginResetModel();
        endResetModel();
    } else {
        qWarning() << "Invalid JSON response:" << doc.toJson();
        // 回退静态数据...
    }

    m_currentReply->deleteLater();
}

int PostModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_posts.size();
}

QVariant PostModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_posts.size())
        return QVariant();

    const Post &post = m_posts.at(index.row());

    switch (role) {
    case Qt::UserRole + 1: return post.title;
    case Qt::UserRole + 2: return post.author;
    case Qt::UserRole + 3: return post.content;
    case Qt::UserRole + 4: return post.timestamp.toString("yyyy-MM-dd hh:mm");
    case Qt::UserRole + 5: return post.star;
    case Qt::UserRole + 6: return post.comments;
    default: return QVariant();
    }
}

QHash<int, QByteArray> PostModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[Qt::UserRole + 1] = "title";
    roles[Qt::UserRole + 2] = "author";
    roles[Qt::UserRole + 3] = "content";
    roles[Qt::UserRole + 4] = "timestamp";
    roles[Qt::UserRole + 5] = "star";
    roles[Qt::UserRole + 6] = "comments";
    return roles;
}

void PostModel::appendPost(const QString &title, const QString &author, const QString &content, const QString &timestampStr, int star, int comments)
{
    QDateTime timestamp = QDateTime::fromString(timestampStr, "yyyy-MM-dd hh:mm");
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_posts.append({title, author, content, timestamp, star, comments});
    endInsertRows();
    qDebug() << "Appended new post:" << title;
}
