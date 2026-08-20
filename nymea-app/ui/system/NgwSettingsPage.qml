// SPDX-License-Identifier: GPL-3.0-or-later

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright (C) 2013 - 2024, nymea GmbH
* Copyright (C) 2024 - 2025, chargebyte austria GmbH
*
* This file is part of nymea-app.
*
* nymea-app is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* nymea-app is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with nymea-app. If not, see <https://www.gnu.org/licenses/>.
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import Nymea
import Nymea.Ngw

import "qrc:/ui/components"

SettingsPageBase {
    id: root
    title: qsTr("LAN network")
    busy: ngwManager.loading || d.pendingCallId !== -1

    QtObject {
        id: d
        property int pendingCallId: -1
    }

    NgwManager {
        id: ngwManager
        engine: _engine
        onSetLanConfigurationReply: (commandId, error, message) => {
            if (commandId !== d.pendingCallId)
                return

            d.pendingCallId = -1

            if (error === NgwManager.NgwErrorNoError)
                return

            var text = message.length > 0 ? message : qsTr("An unexpected error happened while updating the LAN configuration.")
            var popup = Qt.createComponent(Qt.resolvedUrl("../components/ErrorDialog.qml")).createObject(root, {text: text})
            popup.open()
        }
    }

    function showNetworkAccessWarning(acceptedCallback, rejectedCallback) {
        var dialog = Qt.createComponent(Qt.resolvedUrl("../components/NymeaDialog.qml"));
        var popup = dialog.createObject(app,
                                        {
                                            headerIcon: "qrc:/icons/dialog-warning-symbolic.svg",
                                            title: qsTr("Disable dedicated LAN?"),
                                            text: qsTr("Disabling the dedicated LAN may make this %1 system inaccessible from clients connected through the LAN interface. Do not proceed unless another network path is available.").arg(Configuration.systemName)
                                                  + "\n\n" + qsTr("Do you want to proceed?"),
                                            standardButtons: Dialog.Ok | Dialog.Cancel
                                        });
        popup.open();
        popup.accepted.connect(acceptedCallback)
        popup.rejected.connect(rejectedCallback)
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: app.margins
        Layout.rightMargin: app.margins
        Layout.topMargin: app.margins
        text: qsTr("The dedicated LAN creates a separate local network on this system. When enabled, gateway services and internet sharing can be configured for devices connected to that LAN.")
        wrapMode: Text.WordWrap
        color: Material.color(Material.Grey)
        font.pixelSize: Style.smallFont.pixelSize
    }

    SettingsPageSectionHeader {
        text: qsTr("Dedicated LAN")
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("Dedicated LAN enabled")
        subText: qsTr("Run a separate, dedicated local network on this system")
        prominentSubText: false
        progressive: false
        additionalItem: Switch {
            anchors.verticalCenter: parent.verticalCenter
            enabled: d.pendingCallId === -1
            checked: ngwManager.enabled
            onClicked: {
                if (!checked) {
                    root.showNetworkAccessWarning(
                                function() {
                        d.pendingCallId = ngwManager.setLanConfiguration(false, ngwManager.gatewayServicesAccess, ngwManager.internetSharing)
                        // Clicking writes "checked" directly, which severs the binding above; restore it.
                        checked = Qt.binding(function() { return ngwManager.enabled })
                    },
                    function() {
                        checked = Qt.binding(function() { return ngwManager.enabled })
                    })
                } else {
                    d.pendingCallId = ngwManager.setLanConfiguration(true, ngwManager.gatewayServicesAccess, ngwManager.internetSharing)
                    // Clicking writes "checked" directly, which severs the binding above; restore it.
                    checked = Qt.binding(function() { return ngwManager.enabled })
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: app.margins
        Layout.rightMargin: app.margins
        visible: ngwManager.enabled
        enabled: d.pendingCallId === -1
        spacing: Style.smallMargins

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: qsTr("Gateway services access")
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Which nymea services can be reached from the dedicated LAN")
                wrapMode: Text.WordWrap
                color: Material.color(Material.Grey)
                font.pixelSize: Style.extraSmallFont.pixelSize
            }
        }

        ComboBox {
            id: gatewayServicesAccessComboBox
            Layout.fillWidth: true
            model: [qsTr("Disabled"), qsTr("nymea services only"), qsTr("All ports")]
            currentIndex: ngwManager.gatewayServicesAccess
            onActivated: (index) => {
                if (index === ngwManager.gatewayServicesAccess)
                    return

                d.pendingCallId = ngwManager.setLanConfiguration(ngwManager.enabled, index, ngwManager.internetSharing)
                // Activating writes "currentIndex" directly, which severs the binding above; restore it.
                gatewayServicesAccessComboBox.currentIndex = Qt.binding(function() { return ngwManager.gatewayServicesAccess })
            }
        }
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("Internet sharing")
        subText: qsTr("Share this system's internet connection with the dedicated LAN")
        prominentSubText: false
        progressive: false
        visible: ngwManager.enabled
        additionalItem: Switch {
            anchors.verticalCenter: parent.verticalCenter
            enabled: d.pendingCallId === -1
            checked: ngwManager.internetSharing
            onClicked: {
                d.pendingCallId = ngwManager.setLanConfiguration(ngwManager.enabled, ngwManager.gatewayServicesAccess, checked)
                // Clicking writes "checked" directly, which severs the binding above; restore it.
                checked = Qt.binding(function() { return ngwManager.internetSharing })
            }
        }
    }

    SettingsPageSectionHeader {
        text: ngwManager.enabled ? qsTr("Status: enabled") : qsTr("Status: disabled")
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("LAN interface")
        subText: ngwManager.lanInterface
        progressive: false
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("WAN interface")
        subText: ngwManager.wanInterface
        progressive: false
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("LAN subnet")
        subText: ngwManager.lanCidr
        visible: ngwManager.enabled && ngwManager.lanCidr.length > 0
        progressive: false
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("LAN address")
        subText: ngwManager.lanAddress
        visible: ngwManager.enabled && ngwManager.lanAddress.length > 0
        progressive: false
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("DHCP range")
        subText: ngwManager.dhcpStart + " - " + ngwManager.dhcpEnd
        visible: ngwManager.enabled && ngwManager.dhcpStart.length > 0 && ngwManager.dhcpEnd.length > 0
        progressive: false
    }

    NymeaItemDelegate {
        Layout.fillWidth: true
        text: qsTr("Configured gateway ports")
        subText: ngwManager.configuredGatewayPorts.join(", ")
        visible: ngwManager.enabled && ngwManager.configuredGatewayPorts.length > 0
        progressive: false
    }
}
