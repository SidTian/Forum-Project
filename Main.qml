import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: rootwindow
    visible: true
    width: 800
    height: 600
    maximumWidth: 2400 // 设置窗口最大宽度
    minimumWidth: 600 // 可选：设置最小宽度
    title: qsTr("Forum App")

    Material.theme: Material.Light
    Material.primary: "#409EFF" // Element UI 主色调（蓝色）
    Material.accent: "#66B1FF" // 稍浅的蓝色，用于高亮
    Material.background: "#F5F7FA" // Element UI 浅灰背景

    property string currentUsername: "CurrentUser"
    property string currentUser: ""
    property bool isLoggedIn: false

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

    // 帖子数据模型
    ListModel {
        id: postModel
    }

    LoginDialog {
        id: loginDialog
        onAccepted: {
            if (isLoginMode) {
                isLoggedIn = true
            }
        }
    }

    NewPostDialog {
        id: newPostDialog
    }

    Connections {
        target: loginDialog
        function onLoginResponseReceived(response, isSuccess, message, username) {
            if (isSuccess) {
                // 登录成功：更新状态并显示弹窗
                isLoggedIn = true
                currentUser = username
                console.log("Login successful, user:", username, "Message:", message)
                promptDialog.show(
                    qsTr("Login Success"),
                    qsTr("Welcome, ") + username + "! " + message,
                    function() { loginDialog.close() }  // 关闭登录对话框
                )
            } else {
                // 登录失败：显示错误弹窗
                isLoggedIn = false
                console.log("Login error:", message)
                promptDialog.show(
                    qsTr("Login Failed"),
                    message,
                    null
                )
            }
        }
        function onRegisterResponseReceived(response, isSuccess, message, username) {
                if (isSuccess) {
                    // 注册成功：显示弹窗，并切换到登录模式
                    console.log("Registration successful, username:", username, "Message:", message)
                    promptDialog.show(
                        qsTr("Register Success"),
                        qsTr("Registration successful! ") + message + ". Please login with " + username + ".",
                        function() {
                            loginDialog.isLoginMode = true  // 切换到登录模式
                            loginDialog.username = username // 预填用户名                            loginDialog.open()  // 重新打开登录对话框
                        }
                    )
                } else {
                    // 注册失败：显示错误弹窗
                    console.log("Registration error:", message)
                    promptDialog.show(
                        qsTr("Register Failed"),
                        message,
                        null
                    )
                }
            }

    }

    // 页面进入时发送网络请求获取数据
    Component.onCompleted: {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var posts = JSON.parse(xhr.responseText)
                        postModel.clear() // 清空现有数据
                        for (var i = 0; i < posts.length; i++) {
                            postModel.append({
                                                 "title": posts[i].title,
                                                 "author": posts[i].author,
                                                 "content": posts[i].content,
                                                 "timestamp": posts[i].timestamp,
                                                 "star": posts[i].star,
                                                 "comments": posts[i].comments
                                             })
                        }
                        console.log("Fetched", posts.length, "posts from API")
                    } catch (e) {
                        console.error("Failed to parse response:", e)
                        promptDialog.show(
                                    qsTr("Error"), qsTr(
                                        "Failed to load posts: Invalid data format"),
                                    null)
                    }
                } else {
                    console.error("Failed to fetch posts:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"), qsTr(
                                    "Failed to load posts: ") + (xhr.responseText
                                                                 || "Network error"),
                                null)
                }
            }
        }
        xhr.open("GET", "http://34.66.169.26:3000/get_forum_data")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
        console.log("Fetching forum data from API...")
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage

        pushEnter: Transition {
            PropertyAnimation {
                property: "x"
                from: stackView.width
                to: 0
                duration: 200
            }
        }

        popExit: Transition {
            PropertyAnimation {
                property: "x"
                from: 0
                to: stackView.width
                duration: 200
            }
        }

        Rectangle {
            id: mainPage
            anchors.centerIn: parent
            width: Math.min(parent.width, 1000) // 主页面内容最大宽度
            height: parent.height
            color: Material.background

            ColumnLayout {
                anchors.fill: parent

                // header
                ToolBar {
                    Layout.fillWidth: true
                    Material.elevation: 4
                    background: Rectangle {
                        color: Material.primary // 使用 Element UI 蓝色
                        radius: 4 // 轻微圆角
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        Label {
                            text: qsTr("Forum")
                            font.pixelSize: 22 // 更大字体
                            font.bold: true
                            color: "#FFFFFF" // 白色文字，与蓝色背景对比
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ToolButton {
                            text: qsTr("New Post")
                            flat: true
                            Material.foreground: "#FFFFFF" // 白色文字
                            Material.background: Qt.lighter(Material.primary,
                                                            1.2)
                            onClicked: {
                                // if (isLoggedIn) {
                                if (isLoggedIn) {
                                    newPostDialog.open()
                                } else {
                                    promptDialog.show(
                                                qsTr("Login Required"), qsTr(
                                                    "You must log in to create a new post."),
                                                function () {
                                                    loginDialog.open()
                                                })
                                }
                            }
                        }

                        ToolButton {
                            text: isLoggedIn ? qsTr("Logout") : qsTr("Login")
                            flat: true
                            Material.foreground: "#FFFFFF"
                            Material.background: Qt.lighter(Material.primary,
                                                            1.2)
                            onClicked: {
                                loginDialog.username = ""
                                loginDialog.password = ""
                                loginDialog.confirmPassword = ""
                                if (isLoggedIn) {
                                    isLoggedIn = false
                                } else {
                                    loginDialog.open()
                                }
                            }
                        }
                    }
                }

                // 加载指示
                // BusyIndicator {
                //     id: loadingIndicator
                //     Layout.alignment: Qt.AlignCenter
                //     Layout.preferredHeight: 50
                //     Layout.preferredWidth: 50
                //     running: true
                //     visible: true
                // }
                ListView {
                    id: postList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: postModel
                    clip: true
                    spacing: 12 // 增加卡片间距

                    // visible: false
                    delegate: Rectangle {
                        width: postList.width
                        height: 140 // 增加高度以容纳新字段
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 10 // 更大圆角
                        Material.elevation: mouseArea.containsMouse ? 6 : 3 // 悬停时增加阴影
                        color: "#FFFFFF" // 白色卡片，与 Element UI 背景对比

                        // 鼠标交互
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Navigating to post:", title)
                                stackView.push("qrc:/PostDetails.qml", {
                                                   "postData": {
                                                       "title": title,
                                                       "author": author,
                                                       "content": content,
                                                       "timestamp": timestamp,
                                                       "star": star,
                                                       "comments": comments
                                                   }
                                               })
                            }
                        }

                        // 主布局
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16 // 增加内边距
                            spacing: 8

                            // 标题
                            Label {
                                text: title
                                font.pixelSize: 20 // 更大字体
                                font.bold: true
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            // 作者和时间
                            Label {
                                text: qsTr("By ") + author + " | " + timestamp
                                font.pixelSize: 12
                                color: Material.secondaryTextColor
                                Layout.fillWidth: true
                            }

                            // 内容
                            Label {
                                text: content
                                font.pixelSize: 14
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            // Star 和 Comments
                            RowLayout {
                                spacing: 16
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                Label {
                                    text: "★ " + star // 使用 Unicode 星号
                                    font.pixelSize: 12
                                    color: Material.accent // 使用主题高亮色
                                }

                                Label {
                                    text: "💬 " + comments // 使用 Unicode 消息图标
                                    font.pixelSize: 12
                                    color: Material.accent
                                }
                            }
                        }

                        // 悬停动画
                        Behavior on Material.elevation {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    // 滚动条美化
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

            // 监听数据加载信号
            // Connections {
            //     target: postModel
            //     function onDataLoaded(success) {
            //         if (success) {
            //             loadingIndicator.visible = false
            //             loadingIndicator.running = false
            //             postList.visible = true
            //             console.log("Posts loaded successfully, showing ListView")
            //         } else {
            //             loadingIndicator.visible = false
            //             promptDialog.show(
            //                         qsTr("Error"), qsTr(
            //                             "Failed to load posts. Showing fallback data."),
            //                         null)
            //             postList.visible = true // 显示回退数据
            //         }
            //     }
            // }
        }
    }
}
