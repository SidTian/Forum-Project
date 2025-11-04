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
            visible: !isLoginMode // 仅在注册模式显示
        }

        Label {
            id: errorLabel
            text: ""
            color: Material.Red
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text !== ""
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
                errorLabel.text = ""
            }
        }
    }
    onAccepted: {
        errorLabel.text = ""
        if (isLoginMode) {
            loginManager.login(usernameField.text, passwordField.text)
            // 清空字段
            usernameField.text = ""
            passwordField.text = ""
            confirmPasswordField.text = ""
        } else {
            // 注册逻辑
            if (passwordField.text !== confirmPasswordField.text) {
                errorLabel.text = qsTr("Passwords do not match")
                return
            }
            if (usernameField.text === "" || passwordField.text === "") {
                errorLabel.text = qsTr("Username and password are required")
                return
            }
        }
    }

    onRejected: {
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        errorLabel.text = ""
    }
}
