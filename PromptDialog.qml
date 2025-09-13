import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: promptDialog
    modal: true
    standardButtons: Dialog.Ok
    anchors.centerIn: parent
    width: 300

    // 动态标题和文本属性
    property string promptTitle: qsTr("Prompt")
    property string promptText: qsTr("Please take an action.")
    property var onAcceptedCallback: null // 回调函数

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

    onAccepted: {
        if (onAcceptedCallback) {
            onAcceptedCallback()
        }
    }

    // 提供一个函数来显示对话框
    function show(title, text, callback) {
        promptTitle = title
        promptText = text
        onAcceptedCallback = callback
        open()
    }
}
