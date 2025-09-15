
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

    property bool isLoggedIn: false

    ListModel {
        id: postModel
        ListElement { title: "Welcome to the Forum!"; author: "Admin"; content: "This is the first post."; timestamp: "2025-09-13 15:25" }
        ListElement { title: "Qt is Awesome"; author: "User1"; content: "Let's discuss Qt development!"; timestamp: "2025-09-13 14:00" }
    }

    LoginDialog {
        id: loginDialog
        onAccepted: {
            if (isLoginMode) {
                isLoggedIn = true
                console.log("User logged in")
            }
        }
    }

    NewPostDialog {
        id: newPostDialog
    }

    ColumnLayout {
        anchors.fill: parent

        ToolBar {
            Layout.fillWidth: true
            Material.elevation: 4

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Label {
                    text: qsTr("Forum")
                    font.pixelSize: 20
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                ToolButton {
                    text: qsTr("New Post")
                    onClicked: {
                        if (isLoggedIn) {
                            newPostDialog.open()
                        } else {
                            globalPromptDialog.show(
                                qsTr("Login Required"),
                                qsTr("You must log in to create a new post."),
                                function() { loginDialog.open() }
                            )
                        }
                    }
                }

                ToolButton {
                    text: isLoggedIn ? qsTr("Logout") : qsTr("Login")
                    onClicked: {
                        if (isLoggedIn) {
                            isLoggedIn = false
                            console.log("User logged out")
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
            spacing: 8

            delegate: Rectangle {
                width: postList.width - 20
                height: 120
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 8
                color: Material.background
                Material.elevation: 2

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
            }
        }
    }
}
