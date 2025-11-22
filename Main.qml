import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

// import "qrc:/HttpClient.js" as HttpClient
ApplicationWindow {
    id: rootwindow
    visible: true
    width: 800
    height: 600
    maximumWidth: 2400 // windows width
    minimumWidth: 600
    title: qsTr("Forum App")

    Material.theme: Material.Light
    Material.primary: "#409EFF"
    Material.accent: "#66B1FF"
    Material.background: "#F5F7FA"

    property string currentUser: "" // username
    property string userId: "" //user id
    property string userRole: "visitor" // user role
    property bool isLoggedIn: false
    property int selectedChannelId: 1 // channel id

    // property var http: HttpClient // create instance
    // Channel data model
    ListModel {
        id: channelModel
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

    // post data model
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
        function onLoginResponseReceived(response, isSuccess, message) {
            // console.log("isSuccess: " + isSuccess)
            if (isSuccess) {
                // print object
                // for (let key in response)
                //   if (response.hasOwnProperty(key))
                //     console.log(`${key}: ${response[key]}`);

                // set the property
                isLoggedIn = true
                currentUser = response.username
                userRole = response.role
                userId = response.userId

                // console.log("Login successful, user:", username,
                //             "Message:", message, ", userId: ",userId)

                // show prompt dialog
                promptDialog.show(
                            qsTr("Login Success"), qsTr(
                                "Welcome, ") + response.username + "! " + message,
                            null)
                // refresh the page
                loadChannels()
            } else {
                // login failed, alert
                // have not done yet, based on response code, tell the user what's the problem
                isLoggedIn = false
                console.log("Login error:", message)
                promptDialog.show(qsTr("Login Failed"), message, null)
            }
        }

        function onRegisterResponseReceived(response, isSuccess, message, username) {
            if (isSuccess) {
                // register success
                console.log("Registration successful, username:", username,
                            "Message:", message)
                promptDialog.show(qsTr("Register Success"),
                                  qsTr("Registration successful! ") + message
                                  + ". Please login with " + username + ".",
                                  () => {
                                      loginDialog.isLoginMode = true // switch to login mode
                                      loginDialog.open(
                                          ) // reopen the login dialog
                                  })
            } else {
                // Register Failed, show the alert
                // have not done yet, based on response code, tell the user what's the problem
                console.log("Registration error:", message)
                promptDialog.show(qsTr("Register Failed"), message, null)
            }
        }
    }

    Component.onCompleted: {
        loadChannels()
        // httpClientSetup()
    }

    // function httpClientSetup() {
    //     // console.log('QML http loaded: ', typeof http) // "object"
    //     // console.log('QML get method: ', typeof http.get) // "function"！
    //     // console.log('QML defaults: ', typeof http.defaults) // "object"

    //     http.defaults.baseURL = "http://sidtian.com:3000"
    //     // console.log('baseURL set: ', http.defaults.baseURL) // 正常
    // }

    // load channels function
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
                            // selectedChannelId = channelModel.get(
                            //             0).id
                            selectedChannelId = 1
                            loadPosts(selectedChannelId) // reload the post
                        } else {
                            postModel.clear()
                        }
                    } catch (e) {
                        console.error("Failed to parse channels:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Failed to load channels"), null)
                        postModel.clear() // clear the post
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
        // console.log("Fetching channels from API...")
    }

    // load posts function (based on channelId)
    function loadPosts(channelId) {
        // loadingIndicator.running = true
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // loadingIndicator.running = false
                if (xhr.status === 200) {
                    try {
                        var posts = JSON.parse(xhr.responseText)
                        postModel.clear()
                        for (var i = 0; i < posts.length; i++) {
                            postModel.append({
                                                 "title": posts[i].title,
                                                 "author": posts[i].author,
                                                 "content": posts[i].content,
                                                 "timestamp": posts[i].timestamp,
                                                 "star": posts[i].star,
                                                 "comments": posts[i].comments,
                                                 "isLocked": posts[i].isLocked,
                                                 "postId": posts[i].postId
                                             })
                        }
                        // console.log("Loaded", posts.length,
                        //             "posts for channel", channelId)
                        if (userRole !== "admin") {
                            // if post is locked, don't show
                            for (var j = postModel.count - 1; j >= 0; j--) {
                                if (postModel.get(j).isLocked) {
                                    postModel.remove(
                                                j, 1) // remove the locked post
                                }
                            }
                        }
                    } catch (e) {
                        console.error("Failed to parse posts:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Failed to load posts"), null)
                    }
                } else {
                    console.error("Failed to load posts:", xhr.status)
                    promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to load posts: Network error"),
                                null)
                }
            }
        }
        var url = "http://sidtian.com:3000/get_posts?channelId=" + channelId
        xhr.open("GET", url)
        xhr.send()
        // console.log("Fetching posts for channel:", channelId)
    }

    // search function
    function performSearch() {
        const keyword = searchField.text.trim()
        if (keyword === "") {
            promptDialog.show(qsTr("search alert"), qsTr("please give input keyword"), null)
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        var posts = []
                        if (Array.isArray(response)) {
                            posts = response
                        } else if (response.posts) {
                            posts = response.posts
                        } else if (response.results) {
                            posts = response.results
                        }

                        postModel.clear()

                        if (posts.length === 0) {
                            console.log("search no result:", keyword)
                            promptDialog.show(qsTr("Search no result"), qsTr("didn't find post"), null)
                            return
                        }

                        // fill the data
                        for (var i = 0; i < posts.length; i++) {
                            var p = posts[i]
                            postModel.append({
                                "postId": p.postId || 0,
                                "title": p.highlightedTitle || p.title || qsTr("no title"),
                                "author": p.author || "",
                                "content": p.highlightedContent || p.content || "",
                                "timestamp": p.timestamp || "",
                                "star": parseInt(p.star) || 0,
                                "comments": parseInt(p.comments) || 0,
                                "isLocked": p.isLocked ,
                                "channel": p.channel || "General"
                            })
                        }

                        console.log("search :", posts.length, " result:", keyword)

                        // lock the post
                        if (userRole !== "admin") {
                            for (var j = postModel.count - 1; j >= 0; j--) {
                                if (postModel.get(j).isLocked) {
                                    postModel.remove(j, 1)
                                }
                            }
                        }

                    } catch (e) {
                        console.error("parse error:", e)
                        promptDialog.show(qsTr("error"), qsTr("error in load result"), null)
                    }
                } else {
                    console.error("error:", xhr.status)
                    promptDialog.show(qsTr("error"), qsTr("network error"), null)
                }
            }
        }

        xhr.open("POST", "http://sidtian.com:3000/search")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({ query: keyword }))

        console.log("searching:", keyword)
    }

    // switch post islock state (not done yet)
    function togglePostLock(postIndex, currentIsLocked, postId, currentUsername) {
        // optismic update
        postModel.setProperty(postIndex, "isLocked", !currentIsLocked)

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {

                            // console.log("Lock status updated:", response.message)
                            // loadChannels() // refresh the channel and post
                        } else {
                            console.error("Lock update failed:",
                                          response.message)
                            // rollback if failed
                            postModel.setProperty(postIndex, "isLocked",
                                                  currentIsLocked)
                        }
                    } catch (e) {
                        console.error("Failed to parse lock response:", e)
                        // rollback if failed
                        postModel.setProperty(postIndex, "isLocked",
                                              currentIsLocked)
                    }
                } else {
                    console.error("Lock request failed:", xhr.status)
                    // rollback if failed
                    postModel.setProperty(postIndex, "isLocked",
                                          currentIsLocked)
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/lock_post")
        xhr.setRequestHeader("Content-Type", "application/json")
        var lockData = JSON.stringify({
                                          "postId": postId,
                                          "isLocked": !currentIsLocked,
                                          "username": currentUser,
                                          "userId": userId
                                      })
        xhr.send(lockData)
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
            width: Math.min(parent.width, 1000) //main page max width
            height: parent.height
            color: Material.background

            ColumnLayout {
                anchors.fill: parent

                // header
                ToolBar {
                    Layout.fillWidth: true
                    Material.elevation: 4
                    z: 10
                    background: Rectangle {
                        color: Material.primary
                        radius: 4
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Label {
                            text: qsTr("Forum")
                            font.pixelSize: 22
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        Label {
                            text: userRole
                            font.pixelSize: 14
                            font.bold: true
                            color: "#FFFFFF"
                        }

                        // search bar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            TextField {
                                id: searchField
                                placeholderText: qsTr("Search posts...")
                                Layout.fillWidth: true
                                font.pixelSize: 14
                                Material.accent: "#FFFFFF"
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: "#FFFFFF"
                                    border.width: 1
                                    radius: 4
                                }
                                Keys.onReturnPressed: performSearch(
                                                          ) // press Enter for searching
                            }

                            Button {
                                text: qsTr("Search")
                                flat: true
                                Material.foreground: "#FFFFFF"
                                onClicked: performSearch()
                            }
                        }

                        ToolButton {
                            text: qsTr("user detail")
                            flat: true
                            Material.foreground: "#FFFFFF"
                            visible: isLoggedIn
                            Material.background: Qt.lighter(Material.primary,
                                                            1.2)
                            onClicked: {
                                // switch to UserDetail page
                                // pass current user id as parameter
                                // console.log("currentUsername ", currentUser)
                                // console.log("userId ", userId)
                                stackView.push("qrc:/UserDetail.qml", {
                                                   "userId": userId,
                                                   "targetUsername": currentUser
                                               })
                            }
                        }

                        ToolButton {
                            text: qsTr("New Post")
                            flat: true
                            Material.foreground: "#FFFFFF"
                            Material.background: Qt.lighter(Material.primary,
                                                            1.2)
                            onClicked: {
                                // identify if user is log in
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
                                // log out
                                if (isLoggedIn) {
                                    currentUser = "" // clear user state
                                    userRole = "visitor"
                                    userId = ""
                                    selectedChannelId = 0 // reset channel ID
                                    isLoggedIn = false
                                    loadChannels()
                                    postList.forceLayout()
                                    channelList.forceLayout()
                                } else {
                                    // log in
                                    loginDialog.open()
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: postList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: postModel
                    clip: true
                    spacing: 12
                    visible: !loadingIndicator.visible.running

                    delegate: Rectangle {
                        width: postList.width
                        height: 140
                        radius: 10
                        Material.elevation: mouseArea.containsMouse ? 6 : 3
                        border.color: model.isLocked ? "#FF0000" : "#E0E0E0"
                        border.width: model.isLocked ? 2 : 1

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                // switch to PostDetails page with parameter
                                // console.log("Navigating to post:", title)
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
                            Material.accent: model.isLocked ? "#D32F2F" : Material.primaryTextColor // 锁定时红色

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: model.title
                                    font.pixelSize: 20
                                    font.bold: true
                                    color: Material.primaryTextColor
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }

                                // Lock button (only admin can see it)
                                Button {
                                    id: lockButton
                                    text: model.isLocked ? qsTr(
                                                               "Unlock") : qsTr(
                                                               "Lock")
                                    flat: true
                                    Material.accent: Material.Red
                                    visible: userRole === "admin"

                                    onClicked: {
                                        togglePostLock(index, model.isLocked,
                                                       model.postId,
                                                       currentUser)
                                    }
                                }
                            }
                            // author and time
                            Label {
                                text: qsTr("By ") + model.author + " | " + model.timestamp
                                font.pixelSize: 12
                                color: Material.secondaryTextColor
                                Layout.fillWidth: true
                            }

                            // content
                            Label {
                                font.pixelSize: 14
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            // Star and Comment
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

                // load indicator (not done yet)
                BusyIndicator {
                    id: loadingIndicator
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 50
                    running: false
                    visible: running
                    z: 2
                }
            }

            // channels list
            Rectangle {
                id: channels
                x: -100
                y: parent.height / 2 - height / 2
                width: 100
                height: parent.height / 2
                color: "#f0f0f0"
                border.color: "#ccc"
                border.width: 1
                z: 1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    // Channels ListView
                    ListView {
                        id: channelList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: channelModel
                        spacing: 5
                        clip: true

                        delegate: Button {
                            id: channelButton
                            height: 40
                            text: model.name
                            flat: true
                            Material.background: model.id === selectedChannelId ? Material.primary : "transparent"
                            Material.foreground: model.id === selectedChannelId ? "#FFFFFF" : Material.primaryTextColor
                            font.pixelSize: 12

                            onClicked: {
                                selectedChannelId = model.id
                                loadPosts(selectedChannelId) // load post based on ChannelId
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            width: 4
                            background: Rectangle {
                                color: "#ccc"
                                radius: 2
                            }
                            contentItem: Rectangle {
                                color: Material.primary
                                radius: 2
                            }
                        }
                    }

                    // Join Channel button
                    Button {
                        id: joinChannelButton
                        text: qsTr("Join Channel")
                        flat: true
                        Material.background: Material.primary
                        Material.foreground: "#FFFFFF"
                        font.pixelSize: 12
                        height: 40
                        width: parent.width - 10

                        onClicked: {
                            if (isLoggedIn)
                                joinSelectedChannel()
                            else
                                promptDialog.show(
                                            qsTr("login required"),
                                            "You must log in to create a new post.",
                                            () => {
                                                loginDialog.open()
                                            })
                        }
                    }
                }
            }
        }
    }
}
