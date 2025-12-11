import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: newPostDialog
    modal: true
    standardButtons: Dialog.NoButton
    anchors.centerIn: Overlay.overlay
    parent: Overlay.overlay
    width: 520

    background: Rectangle {
        color: "#FFFFFF"
        radius: 20
        border.width: 2
        border.color: "#E2E8F0"
        Material.elevation: 6
    }

    // 当前作者，从 rootwindow 传入
    property string currentAuthor: ""

    /* ---------------------- HEADER ---------------------- */
    header: Rectangle {
        width: parent.width
        height: 110
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 8

            Label {
                text: qsTr("New Post")
                font.pixelSize: 26
                font.bold: true
                color: "#111827"
            }

            Label {
                text: qsTr("Create a new discussion in this channel.")
                font.pixelSize: 14
                color: "#6B7280"
            }

            Label {
                text: qsTr("Author: ") + currentAuthor
                font.pixelSize: 12
                color: "#9CA3AF"
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    /* ---------------------- 中间内容：Title + Content + 按钮 ---------------------- */
    contentItem: ColumnLayout {
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 12
        anchors.bottomMargin: 16
        spacing: 20

        // Title 区域
        ColumnLayout {
            spacing: 6
            Layout.fillWidth: true

            Label {
                text: qsTr("Title")
                font.pixelSize: 14
                font.bold: true
                color: "#1F2937"
            }

            TextField {
                id: titleField
                Layout.fillWidth: true
                placeholderText: qsTr("Enter a concise, descriptive title")

                background: Rectangle {
                    radius: 12
                    color: "#F3F4F6"
                    border.width: 1
                    border.color: titleField.focus ? "#6366F1" : "#E5E7EB"
                }

                leftPadding: 14
                rightPadding: 14
                topPadding: 12
                bottomPadding: 10
            }
        }

        // Content 独立卡片
        Rectangle {
            radius: 14
            color: "#FFFFFF"
            border.width: 1
            border.color: "#E5E7EB"

            Layout.fillWidth: true
            Layout.preferredHeight: 220
            Layout.maximumHeight: 260

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Label {
                    text: qsTr("Content")
                    font.pixelSize: 14
                    font.bold: true
                    color: "#1F2937"
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "#F9FAFB"
                    border.width: 1
                    border.color: contentField.focus ? "#6366F1" : "#E5E7EB"

                    TextArea {
                        id: contentField
                        anchors.fill: parent
                        anchors.margins: 10
                        wrapMode: TextArea.Wrap
                        placeholderText: qsTr("Describe your question, idea, or discussion topic...")
                        font.pixelSize: 14
                    }
                }
            }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 20

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Cancel")
                width: 110
                height: 44

                background: Rectangle {
                    radius: 22
                    border.width: 1
                    border.color: "#D1D5DB"
                    color: "#F8FAFC"
                }

                contentItem: Label {
                    text: qsTr("Cancel")
                    font.pixelSize: 14
                    color: "#6B7280"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: newPostDialog.reject()
            }

            Button {
                text: qsTr("Post")
                width: 130
                height: 44

                background: Rectangle {
                    radius: 22
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#6366F1" }
                        GradientStop { position: 1.0; color: "#8B5CF6" }
                    }
                }

                contentItem: Label {
                    text: qsTr("Post")
                    font.pixelSize: 15
                    font.bold: true
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: newPostDialog.accept()
            }

            Item { Layout.fillWidth: true }
        }
    }

    /* ---------------------- 逻辑部分 ---------------------- */

    onOpened: {
        titleField.focus = true
        currentAuthor = rootwindow.currentUser
    }

    onRejected: {
        titleField.text = ""
        contentField.text = ""
    }

    onAccepted: {
        if (titleField.text === "" || contentField.text === "") {
            promptDialog.show(qsTr("Validation Error"),
                              qsTr("Title and content cannot be empty."), null)
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.code === 1) {
                            titleField.text = ""
                            contentField.text = ""
                            newPostDialog.close()

                            promptDialog.show(
                                qsTr("Success"),
                                qsTr("Post created successfully! ") + response.message,
                                null
                            )

                            loadPosts(selectedChannelId)
                        } else {
                            promptDialog.show(
                                qsTr("Error"),
                                qsTr("Failed to create post: ") + response.message,
                                null
                            )
                        }
                    } catch (e) {
                        promptDialog.show(
                            qsTr("Error"),
                            qsTr("Invalid server response"),
                            null
                        )
                    }
                } else {
                    promptDialog.show(
                        qsTr("Error"),
                        qsTr("Failed to create post: Network error"),
                        null
                    )
                }
            }
        }

        xhr.open("POST", "http://sidtian.com:3000/new_post")
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
            title: titleField.text,
            content: contentField.text,
            author: currentAuthor,
            channel_id: rootwindow.selectedChannelId
        }))
    }
}
