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


    function toggleFollow(targetUsername) {
        if (!rootwindow.isLoggedIn) {
            promptDialog.show("login required", "Please login first", () => {})
            return
        }


        const willFollow = !isFollowing
        isFollowing = willFollow

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {

                            isFollowing = response.isFollowing
                            promptDialog.show(
                                        qsTr(willFollow ? "Follow Success" : "Unfollow Success"),
                                        response.message, null)
                        } else {
                            throw new Error(response.message)
                        }
                    } catch (e) {
                        console.error("Follow request failed:", e)

                        isFollowing = !willFollow
                        promptDialog.show(qsTr("Error"),
                                          e.message || "Operation failed", null)
                    }
                } else {

                    isFollowing = !willFollow
                    promptDialog.show(qsTr("Error"), "Network error", null)
                }
            }
        }

        xhr.open("POST", "http://sidtian.com:3000/follow")
        xhr.setRequestHeader("Content-Type", "application/json")
        var data = JSON.stringify({
                                      "currentUserId": userId,
                                      "targetUsername"
                                      : targetUsername
                                  })
        xhr.send(data)

        console.log("Toggling follow →", targetUsername, "will be:",
                    willFollow ? "followed" : "unfollowed")
    }


    function loadUserDetails(targetUsername) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)


                        if (response.code !== 1) {
                            throw new Error(response.message || "Unknown error")
                        }


                        currentUsername = response.username || targetUsername
                        lastOnlineTime
                                = response.lastOnlineTime ? formatTimestamp(
                                                                response.lastOnlineTime) : "Unknown"
                        isFollowing = !!response.isFollowing


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
                                                          "star"//
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


    function formatTimestamp(mysqlTimestamp) {
        if (!mysqlTimestamp)
            return "Unknown"
        // mysqlTimestamp 可能是 "2025-11-21 19:09:52" 或 "2025-11-21T19:09:52.000Z"
        var dt = new Date(mysqlTimestamp.replace(' ', 'T'))
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
                    width: ListView.view.width
                    height: 160
                    radius: 16
                    color: "#FFFFFF"
                    border.width: postMouseArea.containsMouse ? 2 : 1
                    border.color: postMouseArea.containsMouse ? "#C7D2FE" : "#CBD5E1"
                    Material.elevation: 2

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
                                    text: model.author.charAt(0).toUpperCase()
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#FFFFFF"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        stackView.push("UserDetail.qml", {
                                                           "targetUsername": model.author,
                                                           "currentUsername": rootwindow.currentUser
                                                                              || "",
                                                           "userId": rootwindow.userId
                                                                     || ""
                                                       })
                                    }
                                }
                            }


                            ColumnLayout {
                                spacing: 4

                                RowLayout {
                                    spacing: 6
                                    Label {
                                        text: model.title
                                        font.pixelSize: 18
                                        font.bold: true
                                        color: "#111827"
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        visible: model.isLocked
                                        text: "🔒"
                                        font.pixelSize: 16
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
                                                            "UserDetail.qml", {
                                                                "targetUsername": model.author,
                                                                "currentUsername": rootwindow.currentUser || "",
                                                                "userId": rootwindow.userId
                                                                          || ""
                                                            })
                                            }
                                        }
                                    }

                                    Label {
                                        text: " • " + model.timestamp
                                        font.pixelSize: 12
                                        color: "#6B7280"
                                    }
                                }
                            }
                        }


                        Text {
                            Layout.fillWidth: true
                            text: model.content
                            font.pixelSize: 14
                            color: "#374151"
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
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
                        }
                    }


                    MouseArea {
                        id: postMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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
