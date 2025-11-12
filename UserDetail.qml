import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: userDetailPage
    Material.background: "#F5F7FA"

    // stackView.push value
    property string targetUsername: "Sid" // not done yet
    property string userId: ""

    // user property, get from API
    property string currentUsername: ""
    property string lastOnlineTime: ""
    property bool isFollowing: false

    // send follow/unfollow request (not done yet)
    function followUser(followAction) {
        var action = followAction ? "follow" : "unfollow"
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            isFollowing = followAction
                            promptDialog.show(qsTr(action.charAt(0).toUpperCase(
                                                       ) + action.slice(
                                                       1) + " Success"),
                                              response.message, null)
                        } else {
                            console.error(action + " failed:", response.message)
                            promptDialog.show(qsTr(action.charAt(0).toUpperCase(
                                                       ) + action.slice(
                                                       1) + " Failed"),
                                              response.message, null)
                        }
                    } catch (e) {
                        console.error("Failed to parse response:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Invalid response format"), null)
                    }
                } else {
                    console.error(action + " request failed:", xhr.status)
                    promptDialog.show(qsTr(action.charAt(0).toUpperCase(
                                               ) + action.slice(
                                               1) + " Failed"),
                                      qsTr("Network error"), null)
                }
            }
        }
        var url = "http://sidtian.com:3000/" + action
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        var data = JSON.stringify({
                                      "username": currentUsername,
                                      "userId": userId
                                  })
        xhr.send(data)
        console.log("Sending " + action + " request for user:", currentUsername)
    }

    // get user detail function
    function loadUserDetails(targetUsername) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        // update user info
                        currentUsername = response.username || targetUsername
                        lastOnlineTime = response.lastOnlineTime || "Unknown"
                        isFollowing = response.isFollowing
                        // clear post model
                        userPostsModel.clear()
                        // put new in
                        if (response.posts && response.posts.length > 0) {
                            for (var i = 0; i < response.posts.length; i++) {
                                userPostsModel.append({
                                                          "title": response.posts[i].title,
                                                          "author": response.posts[i].author,
                                                          "content": response.posts[i].content,
                                                          "timestamp": response.posts[i].timestamp,
                                                          "star": response.posts[i].star,
                                                          "comments": response.posts[i].comments
                                                      })
                            }
                            console.log("Loaded", response.posts.length,
                                        "posts for user:", currentUsername)
                        } else {
                            console.log("No posts found for user:",
                                        currentUsername)
                        }
                        // force refresh ListView
                        userPostList.forceLayout()
                    } catch (e) {
                        console.error("Failed to parse user detail response:",
                                      e)
                        promptDialog.show(
                                    qsTr("Error"), qsTr(
                                        "Failed to load user details: Invalid data format"),
                                    null)
                    }
                } else {
                    console.error("Failed to fetch user details:", xhr.status,
                                  xhr.responseText)
                    promptDialog.show(
                                qsTr("Error"), qsTr(
                                    "Failed to load user details: ") + (xhr.responseText
                                                                        || "Network error"),
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
        console.log("Fetching user details from:", url, "Current user:",
                    currentUserName, "Target:", targetUsername)
    }

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

    // get user detail when loading page
    Component.onCompleted: {
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
                            text: qsTr("Stars: ") + getTotalStars(
                                      )
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
                            console.log("Follow button clicked for user:",
                                        currentUsername)
                            if (isFollowing) {
                                followUser(false) // send unfollow request
                            } else {
                                followUser(true) // send follow request
                            }
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
                Layout.preferredHeight: userPostsModel.count
                                        > 0 ? contentHeight : 0
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
                            stackView.push("qrc:/PostDetails.qml", {
                                               "postData": {
                                                   "title": model.title,
                                                   "author": model.author,
                                                   "content": model.content,
                                                   "timestamp": model.timestamp,
                                                   "star": model.star,
                                                   "comments": model.comments
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
