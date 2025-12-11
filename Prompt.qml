// Prompt.qml
pragma Singleton

import QtQuick 2.15
import QtQuick.Controls 2.15

QtObject {
    id: root

    property Dialog _dialog: Dialog {
        id: realDialog
        modal: true
        parent: Overlay.overlay
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape

        width: Math.min(460, contentItem.implicitWidth + 80)
        leftPadding: 40
        rightPadding: 40
        topPadding: 32
        bottomPadding: 32

        background: Rectangle {
            color: "#FFFFFF"
            radius: 20
            border.width: 2
            border.color: "#E2E8F0"
        }

        header: Label {
            text: realDialog.title
            font.pixelSize: 24
            font.bold: true
            color: "#1E293B"
            leftPadding: 12
            topPadding: 20
        }

        Column {
            width: parent.width - 80
            spacing: 20

            Label {
                width: parent.width
                text: realDialog.text
                font.pixelSize: 16
                color: "#475569"
                wrapMode: Text.WordWrap
            }
        }

        footer: DialogButtonBox {
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            onAccepted: {
                if (realDialog._callback)
                    realDialog._callback()
                realDialog.close()
            }
            onRejected: realDialog.close()
        }

        property var _callback: null
    }

    function show(title, message, acceptedCallback) {
        _dialog.title = title || qsTr("Prompt")
        _dialog.text = message || qsTr("Please take an action.")
        _dialog._callback = acceptedCallback || null
        _dialog.open()
    }

    function alert(title, message, callback) {
        _dialog.standardButtons = DialogButtonBox.Ok
        show(title, message, callback)
    }

    function confirm(title, message, callback) {
        _dialog.standardButtons = DialogButtonBox.Ok | DialogButtonBox.Cancel
        show(title, message, callback)
    }
}
