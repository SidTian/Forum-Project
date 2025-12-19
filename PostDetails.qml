import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: postDetailsPage
    Material.background: "#F5F7FA"
    height: 200

    // post data
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
    property bool isStarred: false

    // prompt dialog
    Dialog {
        id: promptDialog
        modal: true
        anchors.centerIn: Overlay.overlay
        width: Math.min(480, implicitContentWidth + 80)
        height: implicitContentHeight + (header ? header.height : 0) + 100
        parent: Overlay.overlay

        property string promptTitle: qsTr("Prompt")
        property string promptText: qsTr("Please take an action.")
        property var onAcceptedCallback: null

        background: Rectangle {
            color: "#FFFFFF"
            radius: 20
            border.width: 2
            border.color: "#E2E8F0"
        }

        header: Rectangle {
            width: parent.width
            height: 80
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24

                Label {
                    text: promptDialog.promptTitle
                    font.pixelSize: 24
                    font.bold: true
                    color: "#1E293B"
                    Layout.fillWidth: true
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: 20
            anchors.margins: 24

            Label {
                text: promptDialog.promptText
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                font.pixelSize: 17
                color: "#334155"
            }
        }

        footer: Rectangle {
            width: parent.width
            height: 80
            color: "transparent"

            Button {
                id: promptOkButton
                text: qsTr("OK")
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: 130
                height: 46

                background: Rectangle {
                    radius: 10
                    color: parent.parent.hovered ? Qt.darker("#6366F1",
                                                             1.1) : "#6366F1"
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                contentItem: Label {
                    text: promptOkButton.text
                    font.pixelSize: 16
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    if (promptDialog.onAcceptedCallback) {
                        promptDialog.onAcceptedCallback()
                    }
                    promptDialog.close()
                }
            }
        }

        function show(title, text, callback) {
            promptTitle = title
            promptText = text
            onAcceptedCallback = callback
            open()
        }
    }

    // get message by post id
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
                                                        || "Unknown",
                                                        "userId": response.messages[i].userId
                                                        || 0
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

    // send message
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

        // send POST request to /message
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            console.log("Response status:", xhr.status)
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // console.log("Raw response:", xhr.responseText)
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            // console.log("Message sent:", response.message)
                            // add to comment list model
                            commentModel.append({
                                                    "author": rootwindow.currentUser,
                                                    "content": commentField.text,
                                                    "timestamp": response.timestamp
                                                })
                            // update number of comment
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

    // get info from single post by post id
    // not in used
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

                            var post = response[0]
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

    function loadPostDetails(postId) {
        if (!postId) {
            console.error("loadPostDetails: postId 为空！");
            return;
        }

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("xhr.status:", xhr.status)
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res.code === 1 && res.post) {
                            // 完全替换 postData
                            postData = {
                                title: res.post.title || "",
                                author: res.post.author || "Anonymous",
                                content: res.post.content || "",
                                timestamp: res.post.timestamp || "",
                                star: res.post.star || 0,
                                comments: res.post.comments || 0,
                                postId: res.post.postId,
                                isLocked: res.post.isLocked || false
                            };

                            // 关键！同步按钮状态
                            isStarred = !!res.post.isStarred;

                            console.log("帖子详情加载成功，当前是否已赞:", isStarred, "star数:", postData.star);
                        }
                    } catch (e) {
                        console.error("解析帖子详情失败:", e);
                    }
                } else {
                    console.error("加载帖子失败:", xhr.status);
                }
            }
        };

        var url = "http://sidtian.com:3000/get_post_detail";
        xhr.open("GET", url + "?postId=" + postId + "&userId=" + (rootwindow.userId || 0));
        xhr.send();
    }

    // star post
    function starPost(postData) {
        if (!postData || !postData.postId) {
            console.error("starPost error：postData or postId is empty！", postData)
            return
        }

        const oldStarred = isStarred
        isStarred = !isStarred

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText)
                        if (res.code === 1) {
                            isStarred = res.isStarred ?? !oldStarred
                            // reload the post
                            loadPostDetails(postData.postId)
                        }
                    } catch (e) {
                        console.error("Star response error:", e)
                        isStarred = oldStarred
                    }
                } else {
                    isStarred = oldStarred
                    promptDialog.show(qsTr("Error"), qsTr("network error"), null)
                }
            }
        }

        xhr.open("POST", "http://sidtian.com:3000/star_post")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
                                    "userId": rootwindow.userId,
                                    "postId": postData.postId
                                }))

        // console.log("send request:", rootwindow.userId, postData.postId)
    }

    // 时间格式化函数（去掉 T 和 Z）
    function formatTime(t) {
        if (!t) return ""

        // 去掉 T 和 Z
        let clean = t.replace("T", " ").replace("Z", "")

        // 显示日期 + 时分
        return clean.substring(0, 16)   // 例如：2025-12-06 23:17
    }


    // call get_message function when get in the page
    Component.onCompleted: {
        get_message()
        refreshTimer.start()
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            id: contentLayout
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: Math.min(parent.width, 1000)
            spacing: 12

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

            // content in scroll view
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250 // fixed height
                clip: true

                ColumnLayout {
                    width: contentLayout.width - 40
                    spacing: 20

                    // title
                    Label {
                        text: postData.title
                        font.pixelSize: 38
                        font.bold: true
                        color: "#0F172A"
                        //horizontalAlignment: Text.AlignLeft
                        horizontalAlignment: Text.AlignHCenter
                        padding: 4
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }
                Item {
                    Layout.fillWidth: true
                    height: authorRow.height


                    Row {
                        id: authorRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8



                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#6366F1" }
                                GradientStop { position: 1.0; color: "#8B5CF6" }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: postData.author && postData.author.length > 0
                                      ? postData.author.charAt(0).toUpperCase()
                                      : "?"
                                color: "#FFFFFF"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("Clicked avatar:", postData.author, "in post")
                                    stackView.push("UserDetail.qml", {
                                        "targetUsername": postData.author,
                                        "currentUsername": rootwindow.currentUser || "",
                                        "userId": rootwindow.userId || -1
                                    })
                                }
                            }
                        }


                        Text {
                            text: postData.author
                            font.pixelSize: 20
                            color: Material.accent
                            font.underline: mouseArea.containsMouse
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    console.log("Clicked author:", postData.author, "in post")
                                    stackView.push("UserDetail.qml", {
                                        "targetUsername": postData.author,
                                        "currentUsername": rootwindow.currentUser || "",
                                        "userId": rootwindow.userId || -1
                                    })
                                }
                            }
                        }


                        Text {
                            text: " | " + formatTime(postData.timestamp)
                            font.pixelSize: 18
                            color: Material.secondaryTextColor
                        }
                    }
                }

                    // content
                    Label {
                        text: postData.content
                        font.pixelSize: 22
                        color: "#334155"
                        padding: 2
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }

                    // Star and Comments
                    RowLayout {
                        spacing: 16
                        Layout.fillWidth: true

                        Button {
                            id: starButton
                            text: isStarred ? "★ " + postData.star : "☆ " + postData.star
                            flat: true
                            Material.foreground: isStarred ? "#FF9800" : Material.accent
                            font.pixelSize: 16

                            onClicked: {
                                if (!rootwindow.isLoggedIn || !rootwindow.userId) {
                                    promptDialog.show(
                                        qsTr("error"),
                                        qsTr("login is required"),
                                        null
                                    )
                                    return
                                }

                                starPost(postData)
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

            // sapaerator line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Material.dividerColor
                visible: commentModel.count > 0
            }

            // comment
            Label {
                text: qsTr("Messages (%1)").arg(commentModel.count)
                font.pixelSize: 18
                font.bold: true
                color: Material.primaryTextColor
                Layout.fillWidth: true
                visible: commentModel.count > 0
            }

            // comment ScrollView
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 250
                clip: true
                visible: commentModel.count > 0

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

                            Text {
                                text: model.author || "Anonymous"
                                font.pixelSize: 18
                                font.bold: true
                                color: Material.accent
                                textFormat: Text.PlainText


                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: parent.font.underline = true
                                    onExited: parent.font.underline = false

                                    onClicked: {
                                        console.log("Comment author clicked:",
                                                    model.author)
                                        stackView.push("UserDetail.qml", {
                                                           "targetUsername": model.author,
                                                           "currentUsername": rootwindow.currentUser
                                                                              || "",
                                                           "userId": rootwindow.userId
                                                                     || 0
                                                       })
                                    }
                                }
                            }

                            Label {
                                text: content
                                font.pixelSize: 16
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Label {
                                text: formatTime(timestamp)
                                font.pixelSize: 14
                                color: Material.secondaryTextColor
                            }
                        }
                    }
                }
            }

            // comment text area
            TextArea {
                id: commentField
                placeholderText: qsTr("Add a message...")
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                font.pixelSize: 14
                Material.accent: Material.Blue
                wrapMode: TextArea.Wrap


                padding: 0
                topPadding: (height - font.pixelSize) / 2
                bottomPadding: topPadding

                background: Rectangle {
                    radius: 8
                    color: "#FFFFFF"
                    Material.elevation: commentField.focus ? 4 : 1
                    border.color: commentField.focus ? Material.accent : Material.dividerColor
                    border.width: 1
                }
            }


            // submit comment button
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
    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: {
            postData.star = postData.star
        }
    }

    // animation page loading
    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutQuad
    }
}
