#ifndef POSTMODEL_H
#define POSTMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QNetworkAccessManager>
#include <QNetworkReply>

struct Post {
    QString title;
    QString author;
    QString content;
    QDateTime timestamp;
    int star;
    int comments;
};

class PostModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit PostModel(QObject *parent = nullptr);

    // QAbstractListModel 接口
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 添加帖子（用于 QML 中的 NewPostDialog）
    Q_INVOKABLE void appendPost(const QString &title, const QString &author, const QString &content, const QString &timestampStr, int star, int comments);

private slots:
    void onNetworkReplyFinished();  // 新增：处理网络响应

private:
    QList<Post> m_posts;
    QNetworkAccessManager *m_networkManager;  // 新增：网络管理器
    QNetworkReply *m_currentReply;  // 新增：当前回复
};

#endif // POSTMODEL_H
