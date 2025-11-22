import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: userDetailPage
    Material.background: "#F5F7FA"

    // stackView.push value
    property string targetUsername: ""
    property string userId: ""

    // user property, get from API
    property string currentUsername: ""
    property string lastOnlineTime: ""
    property bool isFollowing: false

    // user post model
    ListModel {
        id: userPostsModel
    }

    // prompt dialog
    Dialog {
        id: promptDialog
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay
        width: 300
        parent: Overlay.overlay

        property string promptTitle: qsTr("Prompt")
        property string promptText: qsTr("Please take an action.")
        property var onAcceptedCallback: null

        title: promptDialog.promptTitle

        ColumnLayout {
            width: parent.width

            Label {
                text: promptDialog.promptText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }

        onOpened: {

        }

        onAccepted: {
            if (onAcceptedCallback) {
                onAcceptedCallback()
            }
        }

        function show(title, text, callback) {
            promptTitle = title
            promptText = text
            onAcceptedCallback = callback
            open()
        }
    }

    // 统一的关注/取消关注函数（超级好用！）
    function toggleFollow(targetUsername) {
        if (!rootwindow.isLoggedIn) {
            promptDialog.show("login required", "Please login first", () => {})
            return
        }

        // 乐观更新：先改 UI
        const willFollow = !isFollowing
        isFollowing = willFollow // 立即切换按钮状态

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            // 成功！状态已经是对的，不需要再改
                            isFollowing = response.isFollowing
                            promptDialog.show(
                                        qsTr(willFollow ? "Follow Success" : "Unfollow Success"),
                                        response.message, null)
                        } else {
                            throw new Error(response.message)
                        }
                    } catch (e) {
                        console.error("Follow request failed:", e)
                        // 失败回滚
                        isFollowing = !willFollow
                        promptDialog.show(qsTr("Error"),
                                          e.message || "Operation failed", null)
                    }
                } else {
                    // 网络错误也回滚
                    isFollowing = !willFollow
                    promptDialog.show(qsTr("Error"), "Network error", null)
                }
            }
        }

        xhr.open("POST", "http://sidtian.com:3000/follow")
        xhr.setRequestHeader("Content-Type", "application/json")
        var data = JSON.stringify({
                                      "currentUserId": userId,
                                      "targetUsername"// 必须传数字 ID
                                      : targetUsername // 要关注/取消的人的用户名
                                  })
        xhr.send(data)

        console.log("Toggling follow →", targetUsername, "will be:",
                    willFollow ? "followed" : "unfollowed")
    }

    // get user detail function（已完美适配最新后端）
    function loadUserDetails(targetUsername) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // 后端现在一定返回 code === 1 才表示成功
                        if (response.code !== 1) {
                            throw new Error(response.message || "Unknown error")
                        }

                        // 更新用户信息
                        currentUsername = response.username || targetUsername
                        lastOnlineTime
                                = response.lastOnlineTime ? formatTimestamp(
                                                                response.lastOnlineTime) : "Unknown"
                        isFollowing = !!response.isFollowing // 强制转为布尔值

                        // 清空并重新填充帖子模型
                        userPostsModel.clear()

                        if (response.posts && Array.isArray(response.posts)
                                && response.posts.length > 0) {
                            for (var i = 0; i < response.posts.length; i++) {
                                var p = response.posts[i]
                                userPostsModel.append({
                                                          "postId": p.postId,
                                                          "title": p.title
                                                                   || "",
                                                          "author": p.author
                                                                    || currentUsername,
                                                          "content": p.content
                                                                     || "",
                                                          "timestamp": formatTimestamp(
                                                                           p.timestamp),
                                                          "star"// 统一格式化时间
                                                          : p.star !== undefined ? p.star : 0,
                                                          "comments": p.comments !== undefined ? p.comments : 0,
                                                          "isLocked": p.isLocked
                                                                      || false
                                                      })
                            }
                            console.log("Loaded", response.posts.length,
                                        "posts for user:", currentUsername)
                        } else {
                            console.log("No posts found for user:",
                                        currentUsername)
                        }

                        // 强制刷新 ListView
                        userPostList.forceLayout()
                    } catch (e) {
                        console.error(
                                    "Failed to parse or process user detail response:",
                                    e)
                        promptDialog.show(
                                    qsTr("Error"), qsTr(
                                        "Failed to load user details: ") + (e.message
                                                                            || "Invalid data"),
                                    null)
                    }
                } else {
                    // HTTP 非 200（比如 404 用户不存在、500 服务器错误）
                    var errMsg = xhr.responseText ? JSON.parse(
                                                        xhr.responseText).message : "Network error"
                    console.error("Failed to fetch user details:",
                                  xhr.status, errMsg)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to load user details: ") + errMsg,
                                null)
                }
            }
        }

        var url = "http://sidtian.com:3000/user_detail"
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")

        var currentUserName = rootwindow.isLoggedIn ? rootwindow.currentUser : ""

        var data = JSON.stringify({
                                      "currentUsername": currentUserName,
                                      "targetUsername": targetUsername
                                  })

        xhr.send(data)
        console.log("Fetching user details → Target:", targetUsername,
                    "Current:", currentUserName)
    }

    // 可选：统一时间格式化函数（推荐放在全局或这个文件顶部）
    function formatTimestamp(mysqlTimestamp) {
        if (!mysqlTimestamp)
            return "Unknown"
        // mysqlTimestamp 可能是 "2025-11-21 19:09:52" 或 "2025-11-21T19:09:52.000Z"
        var dt = new Date(mysqlTimestamp.replace(' ', 'T')) // 兼容两种格式
        if (isNaN(dt.getTime()))
            return mysqlTimestamp
        return Qt.formatDateTime(dt, "yyyy-MM-dd hh:mm:ss")
    }

    // get user detail when loading page
    Component.onCompleted: {
        // targetUsername = "admin"
        // console.log("currentUsername ", currentUsername)
        // console.log("targetUsername ", targetUsername)
        // console.log("userId ", userId)
        loadUserDetails(targetUsername)
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height

        ColumnLayout {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 1000)
            spacing: 16

            // top tool bar
            ToolBar {
                Layout.fillWidth: true
                Material.elevation: 4
                background: Rectangle {
                    color: Material.primary
                    radius: 4
                }

                RowLayout {
                    anchors.fill: parent

                    ToolButton {
                        text: qsTr("Back")
                        Material.foreground: "#FFFFFF"
                        onClicked: stackView.pop()
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            // user info container
            Rectangle {
                Layout.fillWidth: true
                height: 140
                radius: 10
                color: "#FFFFFF"
                Material.elevation: 4

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    Label {
                        text: currentUsername
                        font.pixelSize: 24
                        font.bold: true
                        color: Material.primaryTextColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Label {
                        text: qsTr("Last Online: ") + lastOnlineTime
                        font.pixelSize: 14
                        color: Material.secondaryTextColor
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // post info
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        Label {
                            text: qsTr("Posts: ") + userPostsModel.count
                            font.pixelSize: 14
                            color: Material.primaryTextColor
                        }

                        Label {
                            text: qsTr("Stars: ") + getTotalStars()
                            font.pixelSize: 14
                            color: Material.primaryTextColor
                        }
                    }

                    // Follow button
                    Button {
                        id: followButton
                        text: isFollowing ? qsTr("Unfollow") : qsTr(
                                                "Follow") // dynamic text
                        flat: true
                        Material.accent: Material.Blue
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8

                        background: Rectangle {
                            color: followButton.pressed ? Qt.darker(
                                                              Material.primary,
                                                              1.1) : (followButton.hovered ? Qt.lighter(Material.primary, 1.1) : Material.primary)
                            radius: 20
                            border.width: 1
                            border.color: Material.primary
                        }

                        contentItem: Text {
                            text: followButton.text
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            // console.log("Follow button clicked for user:",
                            //             targetUsername)
                            toggleFollow(targetUsername)
                        }
                    }
                }
            }

            // post content
            Label {
                text: qsTr("User's Posts")
                font.pixelSize: 18
                font.bold: true
                color: Material.primaryTextColor
                Layout.fillWidth: true
                Layout.topMargin: 20
            }

            // empty
            Label {
                text: qsTr("No posts yet")
                font.pixelSize: 16
                color: Material.secondaryTextColor
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                visible: userPostsModel.count === 0
                Layout.topMargin: 20
            }

            // user post list
            ListView {
                id: userPostList
                Layout.fillWidth: true
                Layout.preferredHeight: userPostsModel.count > 0 ? contentHeight : 0
                model: userPostsModel
                clip: true
                spacing: 12
                visible: userPostsModel.count > 0

                onModelChanged: {
                    forceLayout()
                    console.log("ListView refreshed, count:", count)
                }

                delegate: Rectangle {
                    width: userPostList.width - 24
                    height: 140
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 10
                    color: "#FFFFFF"
                    Material.elevation: 3

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            // console.log("model.postId:",model.postId)
                            stackView.push("qrc:/PostDetails.qml", {
                                               "postData": {
                                                   "title": model.title,
                                                   "author": model.author,
                                                   "content": model.content,
                                                   "timestamp": model.timestamp,
                                                   "star": model.star,
                                                   "comments": model.comments,
                                                   "postId": model.postId
                                               }
                                           })
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Label {
                            text: model.title
                            font.pixelSize: 18
                            font.bold: true
                            color: Material.primaryTextColor
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }

                        Label {
                            text: qsTr("By ") + model.author + " | " + model.timestamp
                            font.pixelSize: 12
                            color: Material.secondaryTextColor
                            Layout.fillWidth: true
                        }

                        Label {
                            text: model.content
                            font.pixelSize: 14
                            color: Material.primaryTextColor
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: 16
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft

                            Label {
                                text: "★ " + model.star
                                font.pixelSize: 12
                                color: Material.accent
                            }

                            Label {
                                text: "💬 " + model.comments
                                font.pixelSize: 12
                                color: Material.accent
                            }
                        }
                    }

                    Behavior on Material.elevation {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    width: 8
                    background: Rectangle {
                        color: Qt.lighter(Material.primary, 1.8)
                        radius: 4
                    }
                    contentItem: Rectangle {
                        color: Material.primary
                        radius: 4
                    }
                }
            }
        }
    }

    // count user all post star
    function getTotalStars() {
        var total = 0
        for (var i = 0; i < userPostsModel.count; i++) {
            total += userPostsModel.get(i).star
        }
        return total
    }

    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutQuad
    }
}
