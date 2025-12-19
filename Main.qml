import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: rootwindow
    visible: true
    width: 900
    height: 650
    maximumWidth: 2400
    minimumWidth: 700
    title: qsTr("Modern Forum")

    Material.theme: Material.Light
    Material.primary: "#6366F1"
    Material.accent: "#8B5CF6"
    Material.background: "#F8FAFC"

    property string currentUser: ""
    property string userId: ""
    property string userRole: "visitor"
    property bool isLoggedIn: false
    property bool loadingPosts: false
    property int selectedChannelId: 1

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#F8FAFC"
            }
            GradientStop {
                position: 1.0
                color: "#EEF2FF"
            }
        }
    }

    ListModel {
        id: channelModel
    }
    ListModel {
        id: postModel
    }

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

        function onLoginResponseReceived(response, isSuccess, message) {
            if (isSuccess) {
                isLoggedIn = true
                currentUser = response.username
                userRole = response.role
                userId = response.userId
                promptDialog.show(
                            qsTr("Login Success"), qsTr(
                                "Welcome, ") + response.username + "! " + message,
                            null)
                loadChannels()
            } else {
                isLoggedIn = false
                console.log("Login error:", message)
                promptDialog.show(qsTr("Login Failed"), message, null)
            }
        }

        function onRegisterResponseReceived(response, isSuccess, message, username) {
            if (isSuccess) {
                console.log("Registration successful, username:", username,
                            "Message:", message)
                promptDialog.show(qsTr("Register Success"),
                                  qsTr("Registration successful! ") + message
                                  + ". Please login with " + username + ".",
                                  () => {
                                      loginDialog.isLoginMode = true
                                      loginDialog.open()
                                  })
            } else {
                console.log("Registration error:", message)
                promptDialog.show(qsTr("Register Failed"), message, null)
            }
        }
    }

    Component.onCompleted: {
        loadChannels()
    }

    function loadChannels() {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var channels = JSON.parse(xhr.responseText)
                        channelModel.clear()
                        for (var i = 0; i < channels.length; i++) {
                            channelModel.append({
                                                    "id": channels[i].id,
                                                    "name": channels[i].name
                                                })
                        }
                        if (channelModel.count > 0) {
                            selectedChannelId = 1
                            loadPosts(selectedChannelId)
                        } else {
                            postModel.clear()
                        }
                    } catch (e) {
                        console.error("Failed to parse channels:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Failed to load channels"), null)
                        postModel.clear()
                    }
                } else {
                    console.error("Failed to load channels:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to load channels: Network error"),
                                null)
                    postModel.clear()
                }
            }
        }
        xhr.open("GET", "http://sidtian.com:3000/channels")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
    }

    function loadPosts(channelId) {
        rootwindow.loadingPosts = true
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                rootwindow.loadingPosts = false
                if (xhr.status === 200) {
                    try {
                        var posts = JSON.parse(xhr.responseText)
                        postModel.clear()
                        var isAdmin = (userRole === "Admin");

                        for (var i = 0; i < posts.length; i++) {
                            var post = posts[i];


                            if (!isAdmin && (post.is_locked === true || post.is_locked === 1)) {
                                continue;
                            }

                            postModel.append({
                                "postId": post.postId,
                                "title": post.title,
                                "author": post.author,
                                "content": post.content,
                                "timestamp": post.timestamp,
                                "star": post.star || 0,
                                "comments": post.comments || 0,
                                "isLocked": post.is_locked || false,

                                "index": postModel.count
                            });
                        }
                    } catch (e) {
                        console.error("Failed to parse posts:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Failed to load posts"), null)
                        postModel.clear()
                    }
                } else {
                    console.error("Failed to load posts:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to load posts: Network error"),
                                null)
                    postModel.clear()
                }
            }
        }
        xhr.open("GET",
                 "http://sidtian.com:3000/get_posts?channelId=" + channelId)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
    }

    // join in channel
    function joinSelectedChannel() {
        // identify selectedChannelId
        if (selectedChannelId === 0) {
            promptDialog.show(qsTr("Error"),
                              qsTr("Please select a channel first"), null)
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            console.log("Joined channel:", response.message)
                            promptDialog.show(qsTr("Success"),
                                              response.message, null)
                        } else if (response.code === 2) {
                            promptDialog.show(qsTr("Error"),
                                              response.message, null)
                        } else {
                            console.error("Join failed:", response.message)
                            promptDialog.show(qsTr("Error"),
                                              response.message, null)
                        }
                    } catch (e) {
                        console.error("Failed to parse join response:", e)
                        promptDialog.show(qsTr("Error"),
                                          "Invalid response", null)
                    }
                } else {
                    console.error("Join request failed:", xhr.status)
                    promptDialog.show(qsTr("Error"), "Network error", null)
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/join_channel")
        xhr.setRequestHeader("Content-Type", "application/json")
        var joinData = JSON.stringify({
                                          "username": currentUser || "",
                                          "userId": userId,
                                          "channelId": selectedChannelId
                                      })
        xhr.send(joinData)
        console.log("Joining channel ID:", selectedChannelId)
    }

    function togglePostLock(index, currentLockState, postId, username) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {

                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {

                            console.log("====================")
                            console.log("success lock")
                            postModel.setProperty(index, "isLocked",
                                                  !currentLockState)
                            promptDialog.show(
                                        qsTr("Success"),
                                        !currentLockState ? qsTr("Post locked successfully") : qsTr(
                                                                "Post unlocked successfully"),
                                        null)
                        } else {
                            promptDialog.show(qsTr("Error"),
                                              response.message, null)
                        }
                    } catch (e) {
                        console.error("Failed to parse response:", e)
                    }
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/lock_post")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
                                    "postId": parseInt(postId),
                                    "username": username,
                                    "isLocked": !currentLockState,
                                    "userId": parseInt(userId)
                                }))
    }

    function formatTime(t) {
        if (!t)
            return ""
        let clean = t.replace("T", " ").replace("Z", "")
        return clean.substring(0, 16)
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: mainPage

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 250
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                property: "x"
                from: stackView.width
                to: 0
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 250
            }
        }
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 250
            }
        }
        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 250
            }
            PropertyAnimation {
                property: "x"
                from: 0
                to: stackView.width
                duration: 250
                easing.type: Easing.InCubic
            }
        }
    }

    Component {
        id: mainPage

        Page {
            background: Rectangle {
                color: "transparent"
            }

            header: Rectangle {
                width: parent.width
                height: 80
                color: "#FFFFFF"
                border.width: 1
                border.color: "#CBD5E1"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 30
                    anchors.rightMargin: 30
                    spacing: 20

                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 45
                            height: 45
                            radius: 12
                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: "#6366F1"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#8B5CF6"
                                }
                            }
                            Label {
                                anchors.centerIn: parent
                                text: "F"
                                font.pixelSize: 24
                                font.bold: true
                                color: "#FFFFFF"
                            }
                        }
                        Label {
                            text: qsTr("Modern Forum")
                            font.pixelSize: 24
                            font.bold: true
                            color: "#1E293B"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 12

                        Button {
                            id: newPostButton
                            text: "✏️ " + qsTr("New Post")
                            visible: isLoggedIn
                            flat: true
                            height: 42
                            font.pixelSize: 14

                            background: Rectangle {
                                radius: 10
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: parent.parent.hovered ? "#7C3AED" : "#6366F1"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: parent.parent.hovered ? "#6D28D9" : "#8B5CF6"
                                    }
                                }
                            }

                            contentItem: Label {
                                text: newPostButton.text
                                font: newPostButton.font
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (isLoggedIn) {
                                    newPostDialog.open()
                                } else {
                                    promptDialog.show(
                                                qsTr("Login required"), qsTr(
                                                    "Please log in to create a new post."),
                                                () => {
                                                    loginDialog.open()
                                                })
                                }
                            }
                        }

                        Rectangle {
                            visible: isLoggedIn
                            width: 180
                            height: 42
                            radius: 21
                            color: "#F1F5F9"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: "#F59E0B"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: "#EF4444"
                                        }
                                    }
                                    Label {
                                        anchors.centerIn: parent
                                        text: currentUser.charAt(
                                                  0).toUpperCase()
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#FFFFFF"
                                    }
                                }

                                ColumnLayout {
                                    spacing: 2
                                    Layout.fillWidth: true
                                    Label {
                                        text: currentUser
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#1E293B"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        text: userRole === "admin" ? "👑 Admin" : "🌟 Member"
                                        font.pixelSize: 10
                                        color: "#64748B"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        hoverEnabled: true
                                        onClicked: {
                                            stackView.push("UserDetail.qml", {
                                                               "userId": userId,
                                                               "targetUsername": currentUser
                                                           })
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            id: loginButton
                            text: isLoggedIn ? qsTr("Logout") : qsTr("Login")
                            flat: true
                            height: 42
                            font.pixelSize: 14

                            background: Rectangle {
                                radius: 10
                                color: parent.parent.hovered ? (isLoggedIn ? "#FEE2E2" : "#EEF2FF") : "transparent"
                                border.width: 2
                                border.color: isLoggedIn ? "#EF4444" : "#6366F1"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }

                            contentItem: Label {
                                text: loginButton.text
                                font: loginButton.font
                                color: isLoggedIn ? "#EF4444" : "#6366F1"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (isLoggedIn) {
                                    isLoggedIn = false
                                    currentUser = ""
                                    userId = ""
                                    userRole = "visitor"
                                    promptDialog.show(
                                                qsTr("Logout"), qsTr(
                                                    "You have been logged out successfully."),
                                                null)
                                } else {
                                    loginDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20

                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    radius: 16
                    color: "#FFFFFF"
                    border.width: 1
                    border.color: "#CBD5E1"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: qsTr("📚 Channels")
                            font.pixelSize: 18
                            font.bold: true
                            color: "#1E293B"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            radius: 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: "#6366F1"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: "#8B5CF6"
                                }
                            }
                        }

                        ListView {
                            id: channelList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: channelModel
                            spacing: 8
                            clip: true

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 48
                                radius: 10
                                color: model.id === selectedChannelId ? "#EEF2FF" : (channelMouseArea.containsMouse ? "#F8FAFC" : "transparent")
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Rectangle {
                                    visible: model.id === selectedChannelId
                                    width: 4
                                    height: parent.height - 12
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 2
                                    gradient: Gradient {
                                        GradientStop {
                                            position: 0.0
                                            color: "#6366F1"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: "#8B5CF6"
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 10

                                    Label {
                                        text: "#"
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: model.id
                                               === selectedChannelId ? "#6366F1" : "#94A3B8"
                                    }
                                    Label {
                                        text: model.name
                                        font.pixelSize: 14
                                        font.bold: model.id === selectedChannelId
                                        color: model.id
                                               === selectedChannelId ? "#1E293B" : "#64748B"
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: channelMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        selectedChannelId = model.id
                                        loadPosts(selectedChannelId)
                                    }
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                active: true
                                width: 6
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    radius: 3
                                    color: parent.pressed ? "#6366F1" : "#CBD5E1"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                        }

                        Button {
                            id: joinChannelButton
                            text: qsTr("➕ Join Channel")
                            Layout.fillWidth: true
                            height: 44
                            flat: true

                            background: Rectangle {
                                radius: 10
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: parent.parent.hovered ? "#7C3AED" : "#6366F1"
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: parent.parent.hovered ? "#6D28D9" : "#8B5CF6"
                                    }
                                }
                            }

                            contentItem: Label {
                                text: joinChannelButton.text
                                font.pixelSize: 13
                                font.bold: true
                                color: "#FFFFFF"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (isLoggedIn) {
                                    joinSelectedChannel()
                                } else {
                                    promptDialog.show(
                                                qsTr("Login required"), qsTr(
                                                    "You must log in to join a channel."),
                                                () => {
                                                    loginDialog.open()
                                                })
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 16

                        BusyIndicator {
                            id: loadingIndicator
                            Layout.alignment: Qt.AlignCenter
                            Layout.preferredHeight: 60
                            Layout.preferredWidth: 60
                            running: rootwindow.loadingPosts
                            visible: rootwindow.loadingPosts
                        }

                        ListView {
                            id: postList
                            visible: !rootwindow.loadingPosts
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: postModel
                            spacing: 16
                            clip: true

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 160
                                radius: 16
                                color: "#FFFFFF"
                                border.width: postMouseArea.containsMouse ? 2 : 1
                                border.color: postMouseArea.containsMouse ? "#C7D2FE" : "#CBD5E1"


                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 10

                                    RowLayout {
                                        spacing: 12


                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: 20
                                            gradient: Gradient {
                                                GradientStop {
                                                    position: 0.0
                                                    color: "#6366F1"
                                                }
                                                GradientStop {
                                                    position: 1.0
                                                    color: "#8B5CF6"
                                                }
                                            }
                                            Label {
                                                anchors.centerIn: parent
                                                text: model.author.charAt(
                                                          0).toUpperCase()
                                                font.pixelSize: 18
                                                font.bold: true
                                                color: "#FFFFFF"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    stackView.push(
                                                                "UserDetail.qml",
                                                                {
                                                                    "targetUsername": model.author,
                                                                    "currentUsername": rootwindow.currentUser || "",
                                                                    "userId": rootwindow.userId
                                                                              || ""
                                                                })
                                                }
                                            }
                                        }


                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6

                                                Label {
                                                    text: model.title
                                                    font.pixelSize: 18
                                                    font.bold: true
                                                    color: "#111827"
                                                }
                                                Label {
                                                    visible: model.isLocked
                                                    text: "🔒"
                                                    font.pixelSize: 16
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }


                                                Item {
                                                    visible: userRole === "admin"
                                                    width: 86
                                                    height: 32

                                                    Rectangle {
                                                        anchors.fill: parent
                                                        radius: 8
                                                        color: lockMouseArea.containsMouse ? "#E0E7FF" : "transparent"
                                                        border.width: lockMouseArea.containsMouse ? 1 : 0
                                                        border.color: "#6366F1"
                                                    }

                                                    Row {
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Text {
                                                            text: model.isLocked ? "🔓" : "🔒"
                                                            font.pixelSize: 14
                                                        }
                                                        Text {
                                                            text: model.isLocked ? "Unlock" : "Lock"
                                                            font.pixelSize: 12
                                                            color: "#6366F1"
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: lockMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor

                                                        onClicked: {


                                                            togglePostLock(
                                                                        model.index,
                                                                        model.isLocked,
                                                                        model.postId,
                                                                        currentUser)


                                                        }
                                                    }
                                                }
                                            }


                                            RowLayout {
                                                spacing: 4
                                                Label {
                                                    text: "by "
                                                    font.pixelSize: 12
                                                    color: "#6B7280"
                                                }
                                                Label {
                                                    id: authorLabel
                                                    text: model.author
                                                    font.pixelSize: 12
                                                    color: "#6366F1"
                                                    font.underline: authorMouseArea.containsMouse
                                                    MouseArea {
                                                        id: authorMouseArea
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            stackView.push(
                                                                        "UserDetail.qml",
                                                                        {
                                                                            "targetUsername": model.author,
                                                                            "currentUsername": rootwindow.currentUser || "",
                                                                            "userId": rootwindow.userId || ""
                                                                        })
                                                        }
                                                    }
                                                }
                                                Label {
                                                    text: " • " + formatTime(
                                                              model.timestamp)
                                                    font.pixelSize: 12
                                                    color: "#6B7280"
                                                }
                                            }
                                        }
                                    }


                                    Text {
                                        Layout.fillWidth: true
                                        text: model.content
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        font.pixelSize: 14
                                        color: "#374151"
                                    }


                                    RowLayout {
                                        spacing: 12

                                        RowLayout {
                                            spacing: 6
                                            Label {
                                                text: "⭐"
                                                font.pixelSize: 16
                                            }
                                            Label {
                                                text: model.star
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: "#F59E0B"
                                            }
                                        }

                                        RowLayout {
                                            spacing: 6
                                            Label {
                                                text: "💬"
                                                font.pixelSize: 16
                                            }
                                            Label {
                                                text: model.comments
                                                font.pixelSize: 13
                                                font.bold: true
                                                color: "#6366F1"
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Label {
                                            visible: model.isLocked
                                            text: "🔒 Locked"
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: "#EF4444"
                                            padding: 6
                                            background: Rectangle {
                                                radius: 6
                                                color: "#FEE2E2"
                                            }
                                        }
                                    }
                                }


                                MouseArea {
                                    id: postMouseArea
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.topMargin: 60
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {

                                        stackView.push("PostDetails.qml", {
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
                            }

                            ScrollBar.vertical: ScrollBar {
                                active: true
                                width: 8
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle {
                                    radius: 4
                                    color: parent.pressed ? "#6366F1" : "#CBD5E1"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
