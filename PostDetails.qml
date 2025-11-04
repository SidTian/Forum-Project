import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Page {
    id: postDetailsPage
    Material.background: "#F5F7FA"
    height: 600
    // 帖子数据属性
    property var postData: ({ title: "", author: "", content: "", timestamp: "", star: 0, comments: 0 })
    property ListModel commentModel: ListModel {}

    // 模拟初始化评论数据
    Component.onCompleted: {
        commentModel.append([
            { author: "User1", content: "Great post!", timestamp: "2025-09-17 12:00" },
            { author: "User2", content: "Thanks for sharing!", timestamp: "2025-09-17 12:30" }
        ])
    }

    // 提示对话框（保持不变）
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
        onOpened: {
            console.log("PromptDialog opened with title:", promptTitle, "text:", promptText)
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

    // 根容器：使用 Item 包裹 ColumnLayout，确保居中
    Item {
        anchors.fill: parent  // 填充整个 Page，但不冲突 StackView

        // 内容布局：动态宽度 + 水平居中
        ColumnLayout {
            id: contentLayout
            anchors.centerIn: parent  // 关键：水平和垂直居中
            // anchors.verticalCenterOffset: 0  // 垂直居中偏移（可选调整）
            width: Math.min(parent.width * 0.8, 1000)  // 动态宽度：窗口宽度的80%，最大1200，避免拉伸
            spacing: 12

            // 顶部工具栏（返回按钮）
            ToolBar {
                Layout.fillWidth: true
                Material.elevation: 4
                background: Rectangle {
                    color: Material.primary  // #409EFF
                    radius: 4
                }

                RowLayout {
                    anchors.fill: parent

                    ToolButton {
                        text: qsTr("Back")
                        Material.foreground: "#FFFFFF"
                        onClicked: stackView.pop()
                    }

                    // Label {
                    //     text: qsTr("Post Details")
                    //     font.pixelSize: 22
                    //     font.bold: true
                    //     color: "#FFFFFF"
                    // }

                    Item { Layout.fillWidth: true }
                }
            }

            // 帖子内容（ScrollView）
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: contentLayout.width - 40  // 内容宽度基于布局宽度，留边距
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
                                    qsTr("You starred the post!"),
                                    null
                                )
                            }
                        }

                        Button {
                            text: "💬 " + postData.comments
                            flat: true
                            Material.foreground: Material.accent
                            onClicked: {
                                commentField.focus = true
                            }
                        }
                    }

                    // 分隔线
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Material.dividerColor
                    }

                    // 评论标题
                    Label {
                        text: qsTr("Comments (%1)").arg(postData.comments)
                        font.pixelSize: 18
                        font.bold: true
                        color: Material.primaryTextColor
                        Layout.fillWidth: true
                    }

                    // 评论列表
                    ListView {
                        id: commentList
                        Layout.fillWidth: true
                        Layout.preferredHeight: contentHeight
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

                    // 评论输入框
                    TextArea {
                        id: commentField
                        placeholderText: qsTr("Add a comment...")
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

                    // 提交评论按钮
                    Button {
                        text: qsTr("Post Comment")
                        highlighted: true
                        Material.accent: Material.Blue
                        Layout.alignment: Qt.AlignRight
                        onClicked: {
                            if (commentField.text === "") {
                                promptDialog.show(
                                    qsTr("Error"),
                                    qsTr("Comment cannot be empty."),
                                    null
                                )
                                return
                            }
                            commentModel.append({
                                author: window.currentUser || "Guest",
                                content: commentField.text,
                                timestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
                            })
                            postData.comments += 1
                            commentField.text = ""
                            promptDialog.show(
                                qsTr("Success"),
                                qsTr("Comment posted successfully!"),
                                null
                            )
                        }
                    }
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
