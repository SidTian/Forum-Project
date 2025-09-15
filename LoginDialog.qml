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

    property bool isLoginMode: true

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
            // 登录逻辑
            console.log("Login attempted with username:", usernameField.text)
            // 可添加登录API调用
            usernameField.text = ""
            passwordField.text = ""
            confirmPasswordField.text = ""
        } else {
            // 注册逻辑
            if (passwordField.text !== confirmPasswordField.text) {
                globalPromptDialog.show(
                    qsTr("Error"),
                    qsTr("Passwords do not match"),
                    null
                )
                return
            }
            if (usernameField.text === "" || passwordField.text === "") {
                globalPromptDialog.show(
                    qsTr("Error"),
                    qsTr("Username and password are required"),
                    null
                )
                return
            }

            // 调用注册API
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200 || xhr.status === 201) {
                        // 注册成功
                        console.log("Registration successful:", xhr.responseText)
                        globalPromptDialog.show(
                            qsTr("Success"),
                            qsTr("Registration successful! Please login."),
                            function() { isLoginMode = true }
                        )
                        usernameField.text = ""
                        passwordField.text = ""
                        confirmPasswordField.text = ""
                    } else {
                        // 注册失败
                        console.log("Registration failed:", xhr.status, xhr.responseText)
                        globalPromptDialog.show(
                            qsTr("Error"),
                            qsTr("Registration failed: ") + (xhr.responseText || "Unknown error"),
                            null
                        )
                    }
                }
            }
            xhr.open("POST", "http://localhost:3000/register")
            xhr.setRequestHeader("Content-Type", "application/json")
            var data = JSON.stringify({
                username: usernameField.text,
                password: passwordField.text
            })
            xhr.send(data)
            return
        }
    }

    onRejected: {
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
}
