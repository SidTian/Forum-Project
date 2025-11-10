import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: newPostDialog
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: Overlay.overlay
    parent: Overlay.overlay
    width: 450
    height: 350
    background: Rectangle {
        color: Material.background
        radius: 16
        Material.elevation: 4
    }
    property string currentAuthor: ""

    header: Rectangle {
        color: Material.background
        radius: 16
        height: 80
        width: parent.width
        Material.elevation: 2
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8
            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Label {
                    text: qsTr("New Post")
                    font.pixelSize: 20
                    font.bold: true
                    color: Material.primaryTextColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                color: "transparent"
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                Label {
                    text: qsTr("Author: ") + currentAuthor
                    font.pixelSize: 12
                    color: Material.secondaryTextColor
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: currentAuthor !== ""
                }
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        TextField {
            id: titleField
            placeholderText: qsTr("Enter post title...")
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            font.pixelSize: 16
            Material.accent: Material.Blue
            background: Rectangle {
                radius: 8
                color: Material.background
                Material.elevation: titleField.focus ? 4 : 1
                border.color: titleField.focus ? Material.accent : Material.dividerColor
                border.width: 1
            }
        }
        // 内容输入
        TextArea {
            id: contentField
            placeholderText: qsTr("Enter post content...")
            Layout.fillWidth: true
            Layout.fillHeight: true
            font.pixelSize: 14
            Material.accent: Material.Blue
            wrapMode: TextArea.Wrap
            padding: 10
            topPadding: 12
            background: Rectangle {
                radius: 8
                color: Material.background
                Material.elevation: contentField.focus ? 4 : 1
                border.color: contentField.focus ? Material.accent : Material.dividerColor
                border.width: 1
            }
        }
    }
    footer: RowLayout {
        spacing: 20
        Item {
            Layout.fillWidth: true
        }
        Button {
            text: qsTr("Cancel")
            flat: true
            Material.background: Material.Grey
            onClicked: newPostDialog.reject()
            Layout.preferredWidth: 100
        }
        Button {
            text: qsTr("Post")
            highlighted: true
            Material.accent: Material.Blue
            onClicked: newPostDialog.accept()
            Layout.preferredWidth: 100
        }
        Item {
            Layout.fillWidth: true
        }
    }
    onAccepted: {
        if (titleField.text === "" || contentField.text === "") {
            // 使用你的 PromptDialog 显示错误
            promptDialog.show(qsTr("Validation Error"),
                              qsTr("Title and content cannot be empty."), null)
            return
            // 阻止添加帖子
        }

        // 发送 POST 请求到 /new_post
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            console.log("Post created successfully:", response.message)
                            // 清空输入并关闭
                            titleField.text = ""
                            contentField.text = ""
                            newPostDialog.close()
                            // 成功提示
                            promptDialog.show(qsTr("Success"), qsTr("Post created successfully! " + response.message), null)
                            // 可选：重新加载帖子列表
                            loadPosts(selectedChannelId)
                        } else {
                            console.error("Post creation failed:", response.message)
                            promptDialog.show(qsTr("Error"), qsTr("Failed to create post: ") + response.message, null)
                        }
                    } catch (e) {
                        console.error("Failed to parse response:", e)
                        promptDialog.show(qsTr("Error"), qsTr("Invalid response format"), null)
                    }
                } else {
                    console.error("Post creation request failed:", xhr.status)
                    promptDialog.show(qsTr("Error"), qsTr("Failed to create post: Network error"), null)
                }
            }
        }
        xhr.open("POST", "http://sidtian.com:3000/new_post")
        xhr.setRequestHeader("Content-Type", "application/json")
        var postData = JSON.stringify({
            title: titleField.text,
            content: contentField.text,
            author: currentAuthor,
            channel_id: rootwindow.selectedChannelId
        })
        xhr.send(postData)
        console.log("Sending new post request with title:", titleField.text)
    }
    onRejected: {
        titleField.text = ""
        contentField.text = ""
    }
    onOpened: {
        titleField.focus = true
        currentAuthor = rootwindow.currentUser
    }
    NumberAnimation on opacity {
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.InOutQuad
    }
}
