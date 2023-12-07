import QtQuick 2.0
import QtQuick.Controls 2.15

Component {
    id: invalidHEMSVersionComponent

    Popup {
        id: invalidHEMSVersionPopup
        parent: root
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: parent.width
        height: 100
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        contentItem: Label {
            Layout.fillWidth: true
            Layout.topMargin: app.margins
            Layout.leftMargin: app.margins
            Layout.rightMargin: app.margins
            wrapMode: Text.WordWrap
            text: ""
        }

        onTextChanged: {
            contentItem.text = popup.text
        }
    }
}
