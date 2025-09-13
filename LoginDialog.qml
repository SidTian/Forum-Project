import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: loginDialog
    title: isLoginMode ? qsTr("Login") : qsTr("Register")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: parent
    width: 300

    property bool isLoginMode: true // 初始为登录模式

    ColumnLayout {
        width: parent.width
        spacing: 10

        TextField {
            id: usernameField
            placeholderText: qsTr("Username")
            Layout.fillWidth: true
            focus: true
        }

        TextField {
            id: passwordField
            placeholderText: qsTr("Password")
            Layout.fillWidth: true
            echoMode: TextInput.Password
        }

        TextField {
            id: confirmPasswordField
            placeholderText: qsTr("Confirm Password")
            Layout.fillWidth: true
            echoMode: TextInput.Password
            visible: !isLoginMode
        }

        Button {
            text: isLoginMode ? qsTr("Switch to Register") : qsTr("Switch to Login")
            Layout.fillWidth: true
            flat: true
            onClicked: {
                isLoginMode = !isLoginMode
                usernameField.text = ""
                passwordField.text = ""
                confirmPasswordField.text = ""
            }
        }
    }

    onAccepted: {
        if (isLoginMode) {
            console.log("Login attempted with username:", usernameField.text)
        } else {
            if (passwordField.text === confirmPasswordField.text) {
                console.log("Register attempted with username:", usernameField.text)
            } else {
                console.log("Registration failed: Passwords do not match")
            }
        }
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
    }

    onRejected: {
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
}
