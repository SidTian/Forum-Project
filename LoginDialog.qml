import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: loginDialog
    title: isLoginMode ? qsTr("Login") : qsTr("Register")
    modal: true
    standardButtons: Dialog.NoButton // 移除标准按钮，使用自定义按钮
    anchors.centerIn: parent
    width: 300

    property bool isLoginMode: true // 初始为登录模式
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias email: emailField.text
    property alias confirmPassword: confirmPasswordField.text

    // login signal
    signal loginResponseReceived(variant response, bool isSuccess, string message)

    // 注册响应信号
    signal registerResponseReceived(variant response, bool isSuccess, string message, string username)

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

        TextField {
            id: emailField
            placeholderText: qsTr("email address")
            Layout.fillWidth: true
             visible: !isLoginMode
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
            text: isLoginMode ? qsTr("Switch to Register") : qsTr(
                                    "Switch to Login")
            Layout.fillWidth: true
            flat: true
            onClicked: {
                isLoginMode = !isLoginMode
                usernameField.text = "sidtian"
                passwordField.text = "20020606"
                confirmPasswordField.text = ""
                errorLabel.text = ""
            }
        }

        // 自定义 Submit 按钮
        Button {
            text: isLoginMode ? qsTr("Submit") : qsTr("Register")
            Layout.fillWidth: true
            highlighted: true
            Material.accent: Material.primary
            onClicked: {
                // 手动验证和处理（不自动关闭对话框）
                handleSubmit()
            }
        }

        Button {
            text: "cancel"
            Layout.fillWidth: true
            highlighted: true
            Material.accent: Material.primary
            onClicked: {
                handleCancel()
            }
        }
    }

    // 自定义提交处理函数
    function handleSubmit() {
        errorLabel.text = ""
        if (isLoginMode) {
            // 登录逻辑
            if (usernameField.text === "" || passwordField.text === "") {
                errorLabel.text = qsTr("Username and password are required")
                return
                // 不发送请求，不关闭
            }

            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {

                            // onLoginResponseReceived(response, isSuccess, message)
                            var response = JSON.parse(xhr.responseText)
                            // for (let key in response)
                                // if (response.hasOwnProperty(key))
                                //     // 过滤继承属性
                                //     console.log(`${key}: ${response[key]}`)


                            loginDialog.loginResponseReceived(
                                        response, response.code === 1,
                                        response.message)
                            successTimer.start() // 延迟关闭
                        } catch (e) {
                            console.error("Failed to parse response:", e)
                            loginDialog.loginResponseReceived({
                                                                  "username": "",
                                                                  "role": "visitor",
                                                                  "userId": ""
                                                              }, false,
                                                              "Invalid response format")
                        }
                    } else {
                        console.error("Login request failed:", xhr.status,
                                      xhr.responseText)
                        loginDialog.loginResponseReceived({
                                                              "username": "",
                                                              "role": "visitor",
                                                              "userId": ""
                                                          }, false,
                                                          "Incorrect username or password")
                    }
                }
            }
            xhr.open("POST", "http://sidtian.com:3000/login")
            xhr.setRequestHeader("Content-Type", "application/json")
            var data = JSON.stringify({
                                          "username": usernameField.text,
                                          "password": passwordField.text
                                      })
            xhr.send(data)
            console.log("Sending login request for username:",
                        usernameField.text)
        } else {
            // 注册逻辑
            if (passwordField.text !== confirmPasswordField.text) {
                errorLabel.text = qsTr("Passwords do not match")
                return
                // 不发送请求，不关闭
            }
            if (usernameField.text === "" || passwordField.text === "" || email === "") {
                errorLabel.text = qsTr("incomplete field, please check")
                return
                // 不发送请求，不关闭
            }

            var regXhr = new XMLHttpRequest()
            regXhr.onreadystatechange = function () {
                if (regXhr.readyState === XMLHttpRequest.DONE) {
                    if (regXhr.status === 200 || regXhr.status === 201) {
                        try {
                            var response = JSON.parse(regXhr.responseText)
                            // 发出信号给 Main.qml 处理
                            loginDialog.registerResponseReceived(
                                        response, response.code === 1,
                                        response.message,
                                        response.username || usernameField.text)
                            console.log("Registration response received:",
                                        response)
                            successTimer.start() // 延迟关闭
                        } catch (e) {
                            console.error("Failed to parse response:", e)
                            loginDialog.registerResponseReceived(
                                        null, false,
                                        "Invalid response format", "")
                        }
                    } else {
                        console.error("Registration request failed:",
                                      regXhr.status, regXhr.responseText)
                        loginDialog.registerResponseReceived(null, false,
                                                             "Network error",
                                                             "")
                    }
                }
            }
            regXhr.open("POST", "http://sidtian.com:3000/register")
            regXhr.setRequestHeader("Content-Type", "application/json")
            var regData = JSON.stringify({
                                             "username": usernameField.text,
                                             "password": passwordField.text,
                                             "email": emailField.text
                                         })
            regXhr.send(regData)
            console.log("Sending registration request for username:",
                        usernameField.text)
        }
    }

    // 定时器：显示成功消息后关闭对话框
    Timer {
        id: successTimer
        interval: 1500 // 1.5 秒后关闭
        repeat: false
        onTriggered: {
            loginDialog.close()
        }
    }

    function handleCancel() {
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        errorLabel.text = ""
        loginDialog.close()
    }
}
