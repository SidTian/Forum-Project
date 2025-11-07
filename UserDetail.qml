import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: userDetailPage
    Material.background: "#F5F7FA"

    // 从导航传递的目标用户名（例如 stackView.push 时传递）
    property string targetUsername: "Sid" // 默认 Sid，可从参数动态设置

    // 用户数据属性（从 API 获取）
    property string currentUsername: ""
    property string lastOnlineTime: ""

    // 用户帖子模型
    ListModel {
        id: userPostsModel
    }

    // 提示对话框（复用或本地）
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
        title: promptTitle
        ColumnLayout {
            width: parent.width
            Label {
                text: promptText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
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

    // 页面进入时发送 GET 请求获取用户数据
    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("Raw response:", JSON.stringify(response)) // 调试：打印完整响应
                        // 更新用户信息
                        currentUsername = response.username || targetUsername
                        lastOnlineTime = response.lastOnlineTime || "Unknown"

                        // 清空并填充帖子
                        userPostsModel.clear()
                        if (response.posts && response.posts.length > 0) {
                            for (var i = 0; i < response.posts.length; i++) {
                                userPostsModel.append({
                                    title: response.posts[i].title,
                                    author: response.posts[i].author,
                                    content: response.posts[i].content,
                                    timestamp: response.posts[i].timestamp,
                                    star: response.posts[i].star,
                                    comments: response.posts[i].comments
                                })
                            }
                            console.log("Loaded", response.posts.length, "posts for user:", currentUsername)
                        } else {
                            console.log("No posts found for user:", currentUsername)
                        }
                        // 强制刷新 ListView
                        userPostList.forceLayout()
                    } catch (e) {
                        console.error("Failed to parse user detail response:", e)
                        promptDialog.show(
                            qsTr("Error"),
                            qsTr("Failed to load user details: Invalid data format"),
                            null
                        )
                    }
                } else {
                    console.error("Failed to fetch user details:", xhr.status, xhr.responseText)
                    promptDialog.show(
                        qsTr("Error"),
                        qsTr("Failed to load user details: ") + (xhr.responseText || "Network error"),
                        null
                    )
                }
            }
        }
        var url = "http://34.66.169.26:3000/user_detail?username=" + targetUsername
        xhr.open("GET", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
        console.log("Fetching user details from:", url)
    }

    // 根容器：顶部对齐，水平居中
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height

        ColumnLayout {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, 1000) // 动态宽度，最大 800
            spacing: 16

            // 顶部工具栏
            ToolBar {
                Layout.fillWidth: true
                Material.elevation: 4
                background: Rectangle {
                    color: Material.primary // #409EFF
                    radius: 4
                }

                RowLayout {
                    anchors.fill: parent

                    ToolButton {
                        text: qsTr("Back")
                        Material.foreground: "#FFFFFF"
                        onClicked: stackView.pop()
                    }

                    // Label {
                    //     text: qsTr("User Details")
                    //     font.pixelSize: 22
                    //     font.bold: true
                    //     color: "#FFFFFF"
                    // }

                    Item { Layout.fillWidth: true }
                }
            }

            // 用户信息卡片
            Rectangle {
                Layout.fillWidth: true
                height: 120
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

                    // 帖子统计
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20

                        Label {
                            text: qsTr("Posts: ") + userPostsModel.count
                            font.pixelSize: 14
                            color: Material.primaryTextColor
                        }

                        Label {
                            text: qsTr("Stars: ") + getTotalStars() // 自定义函数计算总星数
                            font.pixelSize: 14
                            color: Material.primaryTextColor
                        }
                    }
                }
            }

            // 帖子列表标题
            Label {
                text: qsTr("User's Posts")
                font.pixelSize: 18
                font.bold: true
                color: Material.primaryTextColor
                Layout.fillWidth: true
                Layout.topMargin: 20
            }

            // 空状态
            Label {
                text: qsTr("No posts yet")
                font.pixelSize: 16
                color: Material.secondaryTextColor
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                visible: userPostsModel.count === 0
                Layout.topMargin: 20
            }

            // 用户帖子列表
            ListView {
                id: userPostList
                Layout.fillWidth: true
                Layout.preferredHeight: userPostsModel.count > 0 ? contentHeight : 0  // 动态高度，避免空时占用空间
                model: userPostsModel
                clip: true
                spacing: 12
                visible: userPostsModel.count > 0 // 仅当有帖子时显示

                // 监听模型变化，强制刷新
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
                            stackView.push("qrc:/PostDetails.qml", {
                                postData: {
                                    title: model.title,
                                    author: model.author,
                                    content: model.content,
                                    timestamp: model.timestamp,
                                    star: model.star,
                                    comments: model.comments
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
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
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

    // 自定义函数：计算用户总星数
    function getTotalStars() {
        var total = 0
        for (var i = 0; i < userPostsModel.count; i++) {
            total += userPostsModel.get(i).star
        }
        return total
    }

    // 页面进入动画
    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutQuad
    }
}
