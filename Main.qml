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

    property string currentUser: ""
    property string userId: ""
    property string userRole: "visitor"
    property bool isLoggedIn: false
    property int selectedChannelId: 1 // 默认 channel ID
    property bool isLocked: false // 帖子锁定状态，从 model 获取

    // Channel 数据模型
    ListModel {
        id: channelModel
    }

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
        function onLoginResponseReceived(response, isSuccess, message) {
            // console.log("isSuccess: " + isSuccess)
            if (isSuccess) {
                // 登录成功：更新状态并显示弹窗
                // for (let key in response)
                //   if (response.hasOwnProperty(key))   // 过滤继承属性
                //     console.log(`${key}: ${response[key]}`);


                isLoggedIn = true
                currentUser = response.username
                userRole = response.role
                userId = response.userId
                // console.log("Login successful, user:", username,
                //             "Message:", message, ", userId: ",userId)
                promptDialog.show(qsTr("Login Success"), qsTr(
                                      "Welcome, ") + response.username + "! " + message,
                                  function () {
                                      loginDialog.close()
                                  } // 关闭登录对话框
                                  )
                loadChannels()
            } else {
                // 登录失败：显示错误弹窗
                isLoggedIn = false
                console.log("Login error:", message)
                promptDialog.show(qsTr("Login Failed"), message, null)
            }
        }
        function onRegisterResponseReceived(response, isSuccess, message, username) {
            if (isSuccess) {
                // 注册成功：显示弹窗，并切换到登录模式
                console.log("Registration successful, username:", username,
                            "Message:", message)
                promptDialog.show(qsTr("Register Success"),
                                  qsTr("Registration successful! ") + message
                                  + ". Please login with " + username + ".",
                                  function () {
                                      loginDialog.isLoginMode = true // 切换到登录模式
                                      loginDialog.username = username // 预填用户名                            loginDialog.open()  // 重新打开登录对话框
                                  })
            } else {
                // 注册失败：显示错误弹窗
                console.log("Registration error:", message)
                promptDialog.show(qsTr("Register Failed"), message, null)
            }
        }
    }

    // 页面进入时发送网络请求获取数据
    Component.onCompleted: {
        loadChannels()
    }

    // 加载 channels 函数（优化版）
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
                            //             0).id // 默认选中第一个
                            selectedChannelId = 1
                            loadPosts(selectedChannelId) // 重新加载帖子
                        } else {
                            postModel.clear()
                        }
                    } catch (e) {
                        console.error("Failed to parse channels:", e)
                        promptDialog.show(qsTr("Error"),
                                          qsTr("Failed to load channels"), null)
                        postModel.clear() // 清空帖子
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
        xhr.open("GET", "http://sidtian.com:3000/channels") // 假设 API 端点
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send()
        // console.log("Fetching channels from API...")
    }
    // 加载帖子函数（基于 channelId）
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
                            // 逆序遍历以避免索引变化问题
                            for (var j = postModel.count - 1; j >= 0; j--) {
                                if (postModel.get(j).isLocked) {
                                    postModel.remove(j, 1) // 移除锁定帖子
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
    // 搜索函数（在 ApplicationWindow 或 mainPage 作用域中定义）
    function performSearch() {
        if (searchField.text === "") {
            promptDialog.show(qsTr("Search Error"),
                              qsTr("Please enter a search keyword."), null)
            return
        }
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        postModel.clear()
                        // 处理直接返回数组的情况（服务器 res.send(array) 会产生 JSON 数组）
                        var searchResults = []
                        if (Array.isArray(response)) {
                            searchResults = response
                        } else {
                            searchResults = response.results
                                    || response.posts || []
                        }
                        if (searchResults.length > 0) {
                            for (var i = 0; i < searchResults.length; i++) {
                                postModel.append({
                                                     "title": searchResults[i].title,
                                                     "author": searchResults[i].author,
                                                     "content": searchResults[i].content,
                                                     "timestamp": searchResults[i].timestamp,
                                                     "star": searchResults[i].star,
                                                     "comments": searchResults[i].comments,
                                                     "channel": searchResults[i].channel
                                                     || "General"
                                                 })
                            }
                            console.log("Search found", searchResults.length,
                                        "posts for:", searchField.text)
                        } else {
                            console.log("No results for:", searchField.text)
                            postModel.clear()
                        }
                    } catch (e) {
                        console.error("Failed to parse search response:", e)
                        promptDialog.show(
                                    qsTr("Search Error"),
                                    qsTr("Failed to load search results."),
                                    null)
                    }
                } else {
                    console.error("Search request failed:", xhr.status)
                    promptDialog.show(qsTr("Search Error"),
                                      qsTr("Failed to search: Network error"),
                                      null)
                }
            }
        }
        var url = "http://sidtian.com:3000/search" // POST URL
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        // 发送查询作为 JSON body
        xhr.send(JSON.stringify({
                                    "query": searchField.text
                                }))
        console.log("Searching for:", searchField.text)
    }
    // 定义函数：切换帖子锁定状态并发送请求
    function togglePostLock(postIndex, currentIsLocked, postId, currentUsername) {
        // 乐观更新：立即切换状态
        postModel.setProperty(postIndex, "isLocked", !currentIsLocked)

        // 发送 API 请求
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {

                            // console.log("Lock status updated:", response.message)
                            // loadChannels() // 刷新频道和帖子
                        } else {
                            console.error("Lock update failed:",
                                          response.message)
                            // 回滚状态
                            postModel.setProperty(postIndex, "isLocked",
                                                  currentIsLocked)
                        }
                    } catch (e) {
                        console.error("Failed to parse lock response:", e)
                        // 回滚状态
                        postModel.setProperty(postIndex, "isLocked",
                                              currentIsLocked)
                    }
                } else {
                    console.error("Lock request failed:", xhr.status)
                    // 回滚状态
                    postModel.setProperty(postIndex, "isLocked",
                                          currentIsLocked)
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/lock_post") // 假设锁定接口
        xhr.setRequestHeader("Content-Type", "application/json")
        var lockData = JSON.stringify({
                                          "postId": postId,
                                          "isLocked": !currentIsLocked,
                                          "username": currentUser,
                                          "userId": userId
                                      })
        xhr.send(lockData)
    }
    // 新增函数：加入选中频道
    function joinSelectedChannel() {
        // 假设当前选中 channel，或动态获取
        if (selectedChannelId === 0) {
            promptDialog.show(qsTr("Error"),
                              qsTr("Please select a channel first"), null)
            return
        }

        // 发送加入频道请求
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
                            // 可选：更新 UI 或刷新列表
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
                                          "channelId": selectedChannelId // 频道 ID
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
            width: Math.min(parent.width, 1000) // 主页面内容最大宽度
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

                        Label {
                            text: userRole
                            font.pixelSize: 14 // 更大字体
                            font.bold: true
                            color: "#FFFFFF" // 白色文字，与蓝色背景对比
                        }

                        // 搜索框
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
                                                          ) // Enter 键搜索
                            }

                            Button {
                                text: qsTr("Search")
                                flat: true
                                Material.foreground: "#FFFFFF"
                                // Material.background: Qt.lighter(
                                //                          Material.primary, 1.2)
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
                                stackView.push("qrc:/UserDetail.qml", {
                                                   "currentUsername": currentUser,
                                                   "userId": userId
                                               }) // 传递用户名
                            }
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
                                    currentUser = "" // 清空用户
                                    userRole = "visitor"
                                    userId = ""
                                    selectedChannelId = 0 // 重置 channel ID
                                    isLoggedIn = false
                                    loadChannels()
                                    postList.forceLayout()
                                    channelList.forceLayout()
                                } else {
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
                    spacing: 12 // 增加卡片间距
                    visible: !loadingIndicator.visible.running

                    // visible: false
                    delegate: Rectangle {
                        width: postList.width
                        height: 140 // 增加高度以容纳新字段
                        // anchors.horizontalCenter: parent.horizontalCenter
                        radius: 10 // 更大圆角
                        Material.elevation: mouseArea.containsMouse ? 6 : 3 // 悬停时增加阴影
                        // color: model.isLocked ? Material.Red : "#FFFFFF" // locked 时红色背景
                        border.color: model.isLocked ? "#FF0000" : "#E0E0E0" // locked 时红色边框
                        border.width: model.isLocked ? 2 : 1 // locked 时加粗边框

                        // 鼠标交互
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                console.log("Navigating to post:", title)
                                stackView.push("qrc:/PostDetails.qml", {
                                    postData: {
                                        title: model.title,
                                        author: model.author,
                                        content: model.content,
                                        timestamp: model.timestamp,
                                        star: model.star,
                                        comments: model.comments,
                                        postId: model.postId // 新增 postId
                                    }
                                })
                            }
                        }

                        // 主布局
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16 // 增加内边距
                            spacing: 8
                            Material.accent: model.isLocked ? "#D32F2F" : Material.primaryTextColor // 锁定时红色

                            // 标题 + Lock 按钮
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: model.title
                                    font.pixelSize: 20 // 更大字体
                                    font.bold: true
                                    color: Material.primaryTextColor
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 1
                                    elide: Text.ElideRight
                                }

                                // Lock 按钮（仅 admin 可见）
                                Button {
                                    id: lockButton
                                    text: model.isLocked ? qsTr(
                                                               "Unlock") : qsTr(
                                                               "Lock")
                                    flat: true
                                    Material.accent: Material.Red // 红色主题，突出锁定
                                    visible: userRole === "admin" // 仅 admin 可见

                                    onClicked: {
                                        togglePostLock(
                                                    index, model.isLocked,
                                                    model.postId,
                                                    currentUser) // 传入 index 和 model 数据
                                    }
                                }
                            }

                            // 作者和时间（始终可见）
                            Label {
                                text: qsTr("By ") + model.author + " | " + model.timestamp
                                font.pixelSize: 12
                                color: Material.secondaryTextColor
                                Layout.fillWidth: true
                            }

                            // 内容（根据锁定状态和用户角色控制可见性）
                            Label {
                                font.pixelSize: 14
                                color: Material.primaryTextColor
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                visible: true // 始终可见，但文本动态变化
                            }

                            // Star 和 Comments（仅锁定时对 admin 显示，或始终显示）
                            RowLayout {
                                spacing: 16
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft

                                Label {
                                    text: "★ " + model.star // 使用 Unicode 星号
                                    font.pixelSize: 12
                                    color: Material.accent // 使用主题高亮色
                                }

                                Label {
                                    text: "💬 " + model.comments // 使用 Unicode 消息图标
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

                // 加载指示
                BusyIndicator {
                    id: loadingIndicator
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 50
                    running: false // 初始停止
                    visible: running // 初始隐藏
                    z: 2 // 确保在上层
                }
            }

            // 左侧浮动 channels 列表
            Rectangle {
                id: channels
                x: -100
                y: parent.height / 2 - height / 2
                width: 100 // 固定宽度
                height: parent.height / 2
                color: "#f0f0f0"
                border.color: "#ccc"
                border.width: 1
                z: 1 // 确保浮动在主页面上方

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 5

                    // Channels ListView
                    ListView {
                        id: channelList
                        Layout.fillWidth: true
                        Layout.fillHeight: true // 占据剩余空间
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
                            font.pixelSize: 12 // 较小字体以适应宽度

                            // 这里可以进行channel修改
                            // 自定义 contentItem 以支持省略号
                            // contentItem: Text {
                            //     text: parent.text
                            //     font: parent.font
                            //     color: parent.Material.foreground
                            //     horizontalAlignment: Text.AlignHCenter
                            //     verticalAlignment: Text.AlignVCenter
                            //     elide: Text.ElideRight // 使用...省略过长文本
                            //     maximumLineCount: 1 // 单行显示
                            // }

                            onClicked: {
                                selectedChannelId = model.id
                                loadPosts(selectedChannelId) // 调用加载帖子函数
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

                    // Join Channel 按钮（在 ListView 下面）
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
                            joinSelectedChannel()
                        }
                    }
                }
            }
        }
    }
}
