import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: loginDialog
    title: isLoginMode ? qsTr("Login") : qsTr("Register")
    modal: true
    standardButtons: Dialog.NoButton // remove the standard dislog button
    anchors.centerIn: parent
    width: 300

    property bool isLoginMode: true // set login mode
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias email: emailField.text
    property alias confirmPassword: confirmPasswordField.text

    // login signal
    signal loginResponseReceived(variant response, bool isSuccess, string message)

    // register signal
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
            visible: !isLoginMode // show in register mode
        }

        TextField {
            id: emailField
            placeholderText: qsTr("email address")
            Layout.fillWidth: true
             visible: !isLoginMode // show in register mode
        }


        // error message
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
                usernameField.text = ""
                passwordField.text = ""
                confirmPasswordField.text = ""
                emailField.text = ""
                errorLabel.text = ""
            }
        }

        // custom submit button
        Button {
            text: isLoginMode ? qsTr("Submit") : qsTr("Register")
            Layout.fillWidth: true
            highlighted: true
            Material.accent: Material.primary
            onClicked: {
                isLoginMode ? login() : register()
            }
        }
        // custom cancel button
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

    // submit function
    function login() {
        errorLabel.text = ""
        if (isLoginMode) {
            // login mode
            if (usernameField.text === "" || passwordField.text === "") {
                errorLabel.text = qsTr("Username and password are required")
                return
                // don't send request, don't close dialog
            }

            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText)

                            // send signal to main page
                            loginDialog.loginResponseReceived(
                                        response, response.code === 1,
                                        response.message)
                            successTimer.start() // delay close
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
            // register mode (not done yet)
            if (passwordField.text !== confirmPasswordField.text) {
                errorLabel.text = qsTr("Passwords do not match")
                return
                // don't send request, don't close dialog
            }
            if (usernameField.text === "" || passwordField.text === "" || email === "") {
                errorLabel.text = qsTr("incomplete field, please check")
                return
                // don't send request, don't close dialog
            }

            var regXhr = new XMLHttpRequest()
            regXhr.onreadystatechange = function () {
                if (regXhr.readyState === XMLHttpRequest.DONE) {
                    if (regXhr.status === 200 || regXhr.status === 201) {
                        try {
                            var response = JSON.parse(regXhr.responseText)
                            // send signal to Main.qml
                            loginDialog.registerResponseReceived(
                                        response, response.code === 1,
                                        response.message,
                                        response.username || usernameField.text)
                            console.log("Registration response received:",
                                        response)
                            successTimer.start() // delay close
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

    // register function
    function register() {
        errorLabel.text = ""
        if (passwordField.text !== confirmPasswordField.text) {
            errorLabel.text = qsTr("Passwords do not match")
            return
            // don't send request, don't close dialog
        }
        if (usernameField.text === "" || passwordField.text === "" || emailField.text === "") {
            errorLabel.text = qsTr("Incomplete fields, please check")
            return
            // don't send request, don't close dialog
        }
        var regXhr = new XMLHttpRequest()
        regXhr.onreadystatechange = function () {
            if (regXhr.readyState === XMLHttpRequest.DONE) {
                if (regXhr.status === 200 || regXhr.status === 201) {
                    try {
                        var response = JSON.parse(regXhr.responseText)
                        // send signal to Main.qml
                        loginDialog.registerResponseReceived(
                                    response, response.code === 1,
                                    response.message,
                                    response.username || usernameField.text)
                        console.log("Registration response received:",
                                    response)
                        successTimer.start() // delay close
                    } catch (e) {
                        console.error("Failed to parse response:", e)
                        loginDialog.registerResponseReceived(
                                    null, false,
                                    "Invalid response format", "")
                    }
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

    // close dialog
    Timer {
        id: successTimer
        interval: 1500 // after 1.5s close
        repeat: false
        onTriggered: {
            loginDialog.close()
        }
    }

    // cancel function
    function handleCancel() {
        usernameField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        errorLabel.text = ""
        loginDialog.close()
    }
}
