import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600
    title: qsTr("Forum App")

    property bool isLoggedIn: false // 默认未登录

    // 应用 Material 风格
    Material.theme: Material.Light
    Material.accent: Material.Blue

    // 模拟数据模型
    ListModel {
        id: postModel
        ListElement {
            title: "Welcome to the Forum!"
            author: "Admin"
            content: "This is the first post."
            timestamp: "2025-09-13 15:25"
        }
        ListElement {
            title: "Qt is Awesome"
            author: "User1"
            content: "Let's discuss Qt development!"
            timestamp: "2025-09-13 14:00"
        }
    }

    // 实例化 LoginDialog
    LoginDialog {
        id: loginDialog
    }

    // 提示对话框
    PromptDialog {
        id: promptDialog
    }

    ColumnLayout {
        anchors.fill: parent

        // 顶部导航栏
        ToolBar {
            Layout.fillWidth: true
            Material.elevation: 4 // 添加阴影

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Label {
                    text: qsTr("Forum")
                    font.pixelSize: 20
                    font.bold: true
                }

                Item {
                    Layout.fillWidth: true
                } // 占位符

                ToolButton {
                    text: qsTr("New Post")
                    icon.source: "qrc:/icons/add.svg"
                    onClicked: {
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
                    text: qsTr("Login")
                    icon.source: "qrc:/icons/login.svg" // 假设有图标资源
                    onClicked: {
                        loginDialog.isLoginMode = true // 确保打开时是登录模式
                        loginDialog.open()
                    }
                }
            }
        }

        // 帖子列表
        ListView {
            id: postList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: postModel
            clip: true
            spacing: 8

            delegate: Rectangle {
                width: postList.width - 20
                height: 120
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 8 // 圆角
                color: Material.background
                Material.elevation: 2 // 卡片阴影效果

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: title
                        font.pixelSize: 18
                        font.bold: true
                        color: Material.primaryTextColor
                    }

                    Label {
                        text: "By " + author + " | " + timestamp
                        font.pixelSize: 12
                        color: Material.secondaryTextColor
                    }

                    Label {
                        text: content
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.Material.elevation = 4 // 鼠标悬停时增加阴影
                    onExited: parent.Material.elevation = 2
                    onClicked: console.log("Clicked post: " + title)
                }
            }
        }
    }
}
