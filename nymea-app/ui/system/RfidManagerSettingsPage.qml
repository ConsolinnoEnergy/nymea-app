// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Nymea
import NymeaApp.Utils
import Nymea.Rfid

import "../components"

SettingsPageBase {
    id: root
    title: qsTr("RFID settings")

    property int pendingCommandId: -1

    function showErrorDialog(text) {
        var popup = errorDialogComponent.createObject(app, {text: text})
        popup.open()
    }

    function syncFromManager() {
        plugInTimeoutField.text = rfidManager.plugInTimeout
        authorizationTimeoutField.text = rfidManager.authorizationTimeout
    }

    header: NymeaHeader {
        text: root.title
        onBackPressed: pageStack.pop()
    }

    RfidManager {
        id: rfidManager
        engine: _engine
    }

    Component {
        id: errorDialogComponent
        ErrorDialog {}
    }

    Component.onCompleted: {
        root.busy = true
        rfidManager.refreshConfig()
    }

    Connections {
        target: rfidManager

        function onGetConfigReply(commandId, error) {
            root.busy = false
            if (error === RfidManager.RfidErrorNoError)
                root.syncFromManager()
            else
                root.showErrorDialog(qsTr("The RFID settings could not be loaded."))
        }

        function onSetConfigReply(commandId, error) {
            if (commandId !== root.pendingCommandId)
                return

            root.busy = false
            root.pendingCommandId = -1
            if (error === RfidManager.RfidErrorNoError)
                pageStack.pop()
            else
                root.showErrorDialog(qsTr("The RFID settings could not be saved."))
        }
    }

    SettingsPageSectionHeader {
        text: qsTr("Authorization timeouts")
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        text: qsTr("Charging only starts once a valid RFID tag has authorized the charger. Set a value to 0 to disable that timeout.")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Plug-in timeout (s)")
        }

        TextField {
            id: plugInTimeoutField
            Layout.preferredWidth: 96
            horizontalAlignment: Text.AlignRight
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 86400 }
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        text: qsTr("Time to plug in the car after a tag has authorized. On timeout the authorization is revoked.")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Authorization timeout (s)")
        }

        TextField {
            id: authorizationTimeoutField
            Layout.preferredWidth: 96
            horizontalAlignment: Text.AlignRight
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 86400 }
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        text: qsTr("Time to present a tag after the car has been plugged in. Disabled (0) by default.")
    }

    Button {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        Layout.topMargin: Style.margins
        text: qsTr("Save")
        enabled: root.pendingCommandId === -1
                 && plugInTimeoutField.acceptableInput
                 && authorizationTimeoutField.acceptableInput
        onClicked: {
            root.busy = true
            root.pendingCommandId = rfidManager.setConfig(parseInt(plugInTimeoutField.text),
                                                          parseInt(authorizationTimeoutField.text))
        }
    }

    BusyIndicator {
        Layout.alignment: Qt.AlignHCenter
        visible: root.pendingCommandId !== -1
    }
}
