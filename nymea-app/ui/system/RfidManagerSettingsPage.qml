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
    property bool configLoaded: false
    property int originalPlugInTimeout: 0
    property int originalAuthorizationTimeout: 0
    property int originalEnrollmentTimeout: 0
    readonly property int plugInTimeout: plugInTimeoutCheckDelegate.checked ? plugInTimeoutSpinBox.value : 0
    readonly property int authorizationTimeout: authorizationTimeoutCheckDelegate.checked ? authorizationTimeoutSpinBox.value : 0
    readonly property int enrollmentTimeout: enrollmentTimeoutCheckDelegate.checked ? enrollmentTimeoutSpinBox.value : 0
    readonly property bool hasChanges: configLoaded
                                       && (plugInTimeout !== originalPlugInTimeout
                                           || authorizationTimeout !== originalAuthorizationTimeout
                                           || enrollmentTimeout !== originalEnrollmentTimeout)

    function showErrorDialog(text) {
        var popup = errorDialogComponent.createObject(app, {text: text})
        popup.open()
    }

    function normalizeTimeout(value) {
        var timeout = parseInt(value)
        if (isNaN(timeout))
            return 0

        return Math.max(0, Math.min(timeout, 86400))
    }

    function syncFromManager() {
        originalPlugInTimeout = normalizeTimeout(rfidManager.plugInTimeout)
        originalAuthorizationTimeout = normalizeTimeout(rfidManager.authorizationTimeout)
        originalEnrollmentTimeout = normalizeTimeout(rfidManager.enrollmentTimeout)

        plugInTimeoutCheckDelegate.checked = originalPlugInTimeout > 0
        plugInTimeoutSpinBox.value = originalPlugInTimeout > 0 ? originalPlugInTimeout : 300

        authorizationTimeoutCheckDelegate.checked = originalAuthorizationTimeout > 0
        authorizationTimeoutSpinBox.value = originalAuthorizationTimeout > 0 ? originalAuthorizationTimeout : 60

        enrollmentTimeoutCheckDelegate.checked = originalEnrollmentTimeout > 0
        enrollmentTimeoutSpinBox.value = originalEnrollmentTimeout > 0 ? originalEnrollmentTimeout : 60

        configLoaded = true
    }

    function saveConfig() {
        root.busy = true
        root.pendingCommandId = rfidManager.setConfig(root.plugInTimeout,
                                                      root.authorizationTimeout,
                                                      root.enrollmentTimeout)
    }

    function handleBack() {
        if (root.pendingCommandId !== -1)
            return

        if (!root.hasChanges) {
            pageStack.pop()
            return
        }

        var popup = discardChangesDialogComponent.createObject(app)
        popup.open()
    }

    header: NymeaHeader {
        text: root.title
        onBackPressed: root.handleBack()
    }

    RfidManager {
        id: rfidManager
        engine: _engine
    }

    Component {
        id: errorDialogComponent
        ErrorDialog {}
    }

    Component {
        id: discardChangesDialogComponent

        NymeaDialog {
            id: discardChangesDialog

            title: qsTr("Unsaved RFID settings")
            text: qsTr("Do you want to save the changes before leaving this page?")
            standardButtons: Dialog.NoButton

            RowLayout {
                Layout.fillWidth: true

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Discard")
                    onClicked: {
                        discardChangesDialog.close()
                        pageStack.pop()
                    }
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Return")
                    onClicked: discardChangesDialog.close()
                }

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Save")
                    enabled: root.pendingCommandId === -1
                    onClicked: {
                        discardChangesDialog.close()
                        root.saveConfig()
                    }
                }
            }
        }
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
        text: qsTr("RFID authorization")
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        text: qsTr("Charging starts after a valid RFID tag authorizes the charger. Time limits can revoke unused authorizations automatically.")
    }

    CheckDelegate {
        id: plugInTimeoutCheckDelegate
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        enabled: root.configLoaded && root.pendingCommandId === -1
        text: qsTr("Limit time to plug in")
    }

    ItemDelegate {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        Layout.preferredHeight: implicitHeight
        topPadding: 0
        bottomPadding: 0
        visible: plugInTimeoutCheckDelegate.checked

        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Plug-in timeout")
            }

            SpinBox {
                id: plugInTimeoutSpinBox
                from: 1
                to: 86400
                editable: true
                enabled: root.configLoaded && root.pendingCommandId === -1
            }

            Label {
                text: qsTr("seconds")
            }
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        visible: plugInTimeoutCheckDelegate.checked
        text: qsTr("After a tag was accepted, the authorization expires if the vehicle is not plugged in within this time.")
    }

    CheckDelegate {
        id: authorizationTimeoutCheckDelegate
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        enabled: root.configLoaded && root.pendingCommandId === -1
        text: qsTr("Limit time to present a tag")
    }

    ItemDelegate {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        Layout.preferredHeight: implicitHeight
        topPadding: 0
        bottomPadding: 0
        visible: authorizationTimeoutCheckDelegate.checked

        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Tag timeout")
            }

            SpinBox {
                id: authorizationTimeoutSpinBox
                from: 1
                to: 86400
                editable: true
                enabled: root.configLoaded && root.pendingCommandId === -1
            }

            Label {
                text: qsTr("seconds")
            }
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        visible: authorizationTimeoutCheckDelegate.checked
        text: qsTr("After the vehicle is plugged in, authorization expires if no valid tag is presented within this time.")
    }

    CheckDelegate {
        id: enrollmentTimeoutCheckDelegate
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        enabled: root.configLoaded && root.pendingCommandId === -1
        text: qsTr("Limit time to scan a new tag")
    }

    ItemDelegate {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        Layout.preferredHeight: implicitHeight
        topPadding: 0
        bottomPadding: 0
        visible: enrollmentTimeoutCheckDelegate.checked

        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: qsTr("Enrollment timeout")
            }

            SpinBox {
                id: enrollmentTimeoutSpinBox
                from: 1
                to: 86400
                editable: true
                enabled: root.configLoaded && root.pendingCommandId === -1
            }

            Label {
                text: qsTr("seconds")
            }
        }
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        font: Style.smallFont
        visible: enrollmentTimeoutCheckDelegate.checked
        text: qsTr("When adding a tag from a charger, the scan request expires if no tag is presented within this time.")
    }

    Button {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        Layout.topMargin: Style.margins
        text: qsTr("Save")
        enabled: root.pendingCommandId === -1 && root.hasChanges
        onClicked: root.saveConfig()
    }

    BusyIndicator {
        Layout.alignment: Qt.AlignHCenter
        visible: root.pendingCommandId !== -1
    }
}
