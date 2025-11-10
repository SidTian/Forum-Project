import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: postDetailsPage
    Material.background: "#F5F7FA"
    height: 200

    // 帖子数据属性（包括 postId）
    property var postData: ({
                                "title": "",
                                "author": "",
                                "content": "",
                                "timestamp": "",
                                "star": 0,
                                "comments": 0,
                                "postId": ""
                            })
    property ListModel commentModel: ListModel {}

    Dialog {
        id: promptDialog
        modal: true
        standardButtons: Dialog.Ok
        anchors.centerIn: Overlay.overlay
        width: 300
        parent: Overlay.overlay

        // 属性定义在组件顶部，确保可见性
        property string promptTitle: qsTr("Prompt")
        property string promptText: qsTr("Please take an action.")
        property var onAcceptedCallback: null

        title: promptTitle

        ColumnLayout {
            width: parent.width

            Label {
                text: promptDialog.promptText // 使用 promptDialog. 前缀明确引用
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }

        onOpened: {
            console.log("PromptDialog opened with title:", promptTitle,
                        "text:", promptText)
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

    function get_message() {
        if (!postData.postId) {
            promptDialog.show(qsTr("Error"), qsTr("Post ID is missing"), null)
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // console.log("Response status:", xhr.status)
                // console.log("Raw response:", xhr.responseText)
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        // for (let i = 0; i < response.length; i++)
                        commentModel.clear()
                        if (response.messages && response.messages.length > 0) {
                            for (var i = 0; i < response.messages.length; i++) {
                                commentModel.append({
                                                        "author": response.messages[i].username
                                                        || "Anonymous",
                                                        "content": response.messages[i].message,
                                                        "timestamp": response.messages[i].timestamp
                                                        || "Unknown"
                                                    })
                            }
                            // console.log("Loaded", response.messages.length,
                            //             "messages for post ID:",
                            //             postData.postId)
                        } else {
                            console.log("No messages for post ID:",
                                        postData.postId)
                        }
                    } catch (e) {
                        console.error("Failed to parse messages:", e)
                        promptDialog.show(
                                    qsTr("Error"), qsTr(
                                        "Failed to load messages: Invalid data format"),
                                    null)
                    }
                } else {
                    console.error("Failed to fetch messages:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"), qsTr(
                                    "Failed to load messages: ") + (xhr.responseText
                                                                    || "Network error"),
                                null)
                }
            }
        }
        var url = "http://sidtian.com:3000/get_message?postId=" + postData.postId
        xhr.open("GET", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
        // console.log("Fetching messages for post ID:", postData.postId)
    }

    function send_message() {
        if (rootwindow.userId === "") {
            promptDialog.show(qsTr("Error"),
                              qsTr("Login to send message"), null)
            return
        }

        if (commentField.text === "") {
            promptDialog.show(qsTr("Error"),
                              qsTr("Message cannot be empty."), null)
            return
        }

        // 发送 POST 请求到 /message
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            console.log("Response status:", xhr.status)
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("Raw response:", xhr.responseText) // 调试：打印原始响应
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            // console.log("Message sent:", response.message)
                            // 添加到本地列表
                            commentModel.append({
                                                    "author": rootwindow.currentUser,
                                                    "content": commentField.text,
                                                    "timestamp": response.timestamp
                                                })
                            // 更新评论计数（动态计算）
                            postData.comments = commentModel.count
                            console.log(postData.comments)
                            commentField.text = ""
                            promptDialog.show(
                                        qsTr("Success"),
                                        qsTr("Message sent successfully!"),
                                        null)
                        } else {
                            console.error("Message send failed:",
                                          response.message)
                            promptDialog.show(
                                        qsTr("Error"), qsTr(
                                            "Failed to send message: ") + response.message,
                                        null)
                        }
                    } catch (e) {
                        console.error("Failed to parse message response:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Invalid response format"), null)
                    }
                } else {
                    console.error("Message send request failed:", xhr.status)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to send message: Network error"),
                                null)
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/send_message")
        xhr.setRequestHeader("Content-Type", "application/json")
        var messageData = JSON.stringify({
                                             "userId": rootwindow.userId,
                                             "username": rootwindow.currentUser,
                                             "content": commentField.text,
                                             "postId": postData.postId
                                         })
        xhr.send(messageData)
        console.log("Sending message for post ID:", postData.postId)
    }

    function get_post() {
        if (!postData.postId) {
            promptDialog.show(qsTr("Error"), qsTr("Post ID is missing"), null)
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response && response.length > 0) {

                            var post = response[0] // 假设返回数组，取第一个
                            console.log(response)
                            postData.title = post.title
                            postData.timestamp = post.timestamp
                            postData.star = post.star
                            postData.comments = post.comments
                            postData.isLocked = post.isLocked
                            console.log("Loaded post data for ID:", postId)
                        } else {
                            console.error("No post data found")
                            promptDialog.show(qsTr("Error"),
                                              qsTr("Post not found"), null)
                        }
                    } catch (e) {
                        console.error("Failed to parse post response:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Invalid data format"), null)
                    }
                } else {
                    console.error("Failed to fetch post:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to load post: Network error"),
                                null)
                }
            }
        }
        var url = "http://sidtian.com:3000/get_post?postId=" + postData.postId
        xhr.open("GET", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
        console.log("Fetching post data for ID:", postId)
    }

    // 页面进入时发送 GET 请求到 /get_message 获取评论数据
    Component.onCompleted: {
        get_message()
    }

    // 根容器：使用 Item 包裹 ColumnLayout，确保居中
    Item {
        anchors.fill: parent // 填充整个 Page，但不冲突 StackView

        // 内容布局：动态宽度 + 水平居中
        ColumnLayout {
            id: contentLayout
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top  // 垂直顶部对齐
            width: Math.min(parent.width, 1000) // 动态宽度：窗口宽度的80%，最大1200，避免拉伸
            spacing: 12

            // 顶部工具栏（返回按钮）
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
                    Item {
                        Layout.fillWidth: true
                    }
                }
            }

            // 帖子内容（ScrollView）
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 200 // 固定帖子内容高度，避免扩展
                clip: true

                ColumnLayout {
                    width: contentLayout.width - 40 // 内容宽度基于布局宽度，留边距
                    spacing: 12

                    // 标题
                    Label {
                        text: postData.title
                        font.pixelSize: 24
                        font.bold: true
                        color: Material.primaryTextColor
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }

                    // 作者和时间
                    Label {
                        text: qsTr("By ") + postData.author + " | " + postData.timestamp
                        font.pixelSize: 14
                        color: Material.secondaryTextColor
                        Layout.fillWidth: true
                    }

                    // 完整内容
                    Label {
                        text: postData.content
                        font.pixelSize: 16
                        color: Material.primaryTextColor
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }

                    // Star 和 Comments
                    RowLayout {
                        spacing: 16
                        Layout.fillWidth: true

                        Button {
                            text: "★ " + postData.star
                            flat: true
                            Material.foreground: Material.accent
                            onClicked: {
                                postData.star += 1
                                promptDialog.show(
                                            qsTr("Starred"),
                                            qsTr("You starred the post!"), null)
                            }
                        }

                        Button {
                            id: commentButton
                            text: "💬 " + commentModel.count
                            flat: true
                            Material.foreground: Material.accent
                            onClicked: {
                                commentField.focus = true
                            }
                        }
                    }
                }
            }

            // 分隔线
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Material.dividerColor
                visible: commentModel.count > 0 // 仅当有评论时显示
            }

            // 评论标题
            Label {
                text: qsTr("Messages (%1)").arg(commentModel.count)
                font.pixelSize: 18
                font.bold: true
                color: Material.primaryTextColor
                Layout.fillWidth: true
                visible: commentModel.count > 0
            }

            // 消息列表（评论列表） - 固定高度 ScrollView
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250 // 固定高度：评论区域高度
                clip: true
                visible: commentModel.count > 0 // 仅当有评论时显示

                ListView {
                    id: commentList
                    anchors.fill: parent
                    model: commentModel
                    spacing: 8
                    clip: true

                    delegate: Rectangle {
                        width: parent.width
                        height: 80
                        radius: 8
                        color: "#FFFFFF"
                        Material.elevation: 2

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4

                            Label {
                                text: author
                                font.pixelSize: 14
                                font.bold: true
                                color: Material.primaryTextColor
                            }

                            Label {
                                text: content
                                font.pixelSize: 12
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Label {
                                text: timestamp
                                font.pixelSize: 10
                                color: Material.secondaryTextColor
                            }
                        }
                    }
                }
            }

            // 消息输入框
            TextArea {
                id: commentField
                placeholderText: qsTr("Add a message...")
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                font.pixelSize: 14
                Material.accent: Material.Blue
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    radius: 8
                    color: "#FFFFFF"
                    Material.elevation: commentField.focus ? 4 : 1
                    border.color: commentField.focus ? Material.accent : Material.dividerColor
                    border.width: 1
                }
            }

            // 提交消息按钮
            Button {
                text: qsTr("Send Message")
                highlighted: true
                Material.accent: Material.Blue
                Layout.alignment: Qt.AlignRight
                onClicked: {
                    send_message()
                }
            }
        }
    }

    // 页面进入动画（保持不变）
    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutQuad
    }
}
