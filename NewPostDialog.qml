import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: newPostDialog
    title: qsTr("New Post")
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    anchors.centerIn: parent
    width: 400

    ColumnLayout {
        width: parent.width

        TextField {
            id: titleField
            placeholderText: qsTr("Post Title")
            Layout.fillWidth: true
        }

        TextArea {
            id: contentField
            placeholderText: qsTr("Post Content")
            Layout.fillWidth: true
            Layout.preferredHeight: 100
        }
    }

    onAccepted: {
        // 假设 postModel 是通过上下文属性传递的
        postModel.append({
            title: titleField.text,
            author: "CurrentUser", // 可动态设置为实际用户名
            content: contentField.text,
            timestamp: Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
        })
        titleField.text = ""
        contentField.text = ""
    }

    onRejected: {
        titleField.text = ""
        contentField.text = ""
    }
}
