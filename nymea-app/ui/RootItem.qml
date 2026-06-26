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
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtCore
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Nymea
import NymeaApp.Utils

import "components"
import "connection"

Item {
    id: root

    function handleAndroidBackButton() {
        return swipeView.currentItem.handleAndroidBackButton()
    }

    QtObject {
        id: d
        // We want only one of them pushed at a time
        property var currentSettingsPage: null

        function pushSettingsPage(page) {
            if (d.currentSettingsPage != null) {
                d.currentSettingsPage = swipeView.currentItem.pageStack.replace(d.currentSettingsPage, page);
            } else {
                d.currentSettingsPage = swipeView.currentItem.pageStack.push(page)
            }
        }
    }

    function openThingSettings() {
        d.pushSettingsPage("thingconfiguration/EditThingsPage.qml")
    }
    function openMagicSettings() {
        d.pushSettingsPage("MagicPage.qml")
    }
    function openAppSettings() {
        d.pushSettingsPage("appsettings/ConsolinnoAppSettingsPage.qml")
    }
    function openSystemSettings() {
        var current = swipeView.currentItem
        if (!current) return
        var page = current.mainPage
        if (!page) return
        current.pageStack.pop(page)
        page.goToView("consolinnoSettings", undefined, true)
    }
    function openCustomPage(page) {
        d.pushSettingsPage(page)
    }

    function configureMainView() {
        swipeView.currentItem.pageStack.pop(null)
        swipeView.currentItem.pageStack.currentItem.configureViews()
    }

    ColumnLayout {
        anchors.fill: parent

        // The window is edge-to-edge. Left/right system insets (display
        // cutout, gesture areas on the sides) are still consumed at the
        // root so page content does not slide under them. Top/bottom
        // insets are intentionally NOT applied here; they are handled by
        // each page's header (CoHeader / MainPage header) and by the
        // navigation footer below so the app chrome can reach the screen
        // edges while the system bars stay system-drawn.
        anchors.leftMargin: SafeArea.margins.left
        anchors.rightMargin: SafeArea.margins.right

        spacing: 0

        SwipeView {
            id: swipeView
            Layout.fillHeight: true
            Layout.fillWidth: true
            interactive: false
            currentIndex: configuredHostsModel.currentIndex

            onCurrentIndexChanged: visibleHackTimer.start();

            // Hack: we only want the current one visible for performance reasons, however, during transitions this might look odd
            // as we need to show two views partially at the same time.
            // Couldn't find a way to determine the swipeView position, so let's assume it's moving for a second after currentIndex changed
            Timer {
                id: visibleHackTimer
                repeat: false
                interval: 500
                running: false
            }

            Repeater {
                id: mainRepeater
                model: configuredHostsModel

                delegate: Item {
                    height: swipeView.height
                    width: swipeView.width
                    clip: true
                    // Consolinno: disable this hack for now
                    visible: SwipeView.isCurrentItem //|| visibleHackTimer.running

                    readonly property ConfiguredHost configuredHost: configuredHostsModel.get(index)

                    property var tabSettings: Settings {
                        category: "tabSettings" + index
                        property int currentMainViewIndex: -1
                    }

                    readonly property Engine engine: configuredHost.engine
                    readonly property Engine _engine: configuredHost.engine // In case a child cannot use "engine"

                    HemsManager {
                        id: hemsManagerInternal
                        engine: _engine
                    }

                    readonly property HemsManager hemsManager: hemsManagerInternal

                    Binding {
                        target: nymeaDiscovery
                        property: "discovering"
                        value: engine.jsonRpcClient.currentHost === null
                               && (PlatformPermissions.localNetworkPermission === PlatformPermissions.PermissionStatusGranted
                                   // This OR wouldn't be needed but we introduced the permission handling later and the localNetworkPerm can't be read on iOS.
                                   // If there are configured hosts, it means that we actally already have the permission even though PlatformPermissions thinks we wouldn't...
                                   // So skipping the check in that case for now (1.6)
                                   || configuredHostsModel.count > 0)

                    }

                    readonly property alias pageStack: _pageStack
                    readonly property var mainPage: (function() {
                        if (!engine.jsonRpcClient.connected || _pageStack.depth === 0) return null
                        for (var i = 0; i < _pageStack.depth; i++) {
                            var p = _pageStack.get(i)
                            if (p && p.hasOwnProperty("tabsModel")) return p
                        }
                        return null
                    })()

                    Binding {
                        target: mainPage
                        property: "navigationFooterHeight"
                        value: navigationFooterContainer.shown ? navigationFooterContainer.height : 0
                        when: mainPage !== null
                    }

                    readonly property var currentStackPage: _pageStack.currentItem

                    Binding {
                        target: currentStackPage
                        property: "navigationFooterHeight"
                        value: navigationFooterContainer.shown ? navigationFooterContainer.height : 0
                        when: currentStackPage !== null
                              && currentStackPage !== mainPage
                              && "navigationFooterHeight" in currentStackPage
                    }

                    StackView {
                        id: _pageStack
                        objectName: "pageStack"
                        anchors.fill: parent
                        initialItem: Page {}
                    }

                    readonly property bool blurEnabled: PlatformHelper.deviceManufacturer !== "raspbian"

                    ShaderEffectSource {
                        id: footerBlurSource
                        width: _pageStack.width
                        height: navigationFooterContainer.height
                        sourceItem: blurEnabled ? _pageStack : null
                        sourceRect: Qt.rect(0, _pageStack.height - height, _pageStack.width, height)
                        recursive: true
                        live: true
                        mipmap: true
                        visible: false
                        enabled: blurEnabled && navigationFooterContainer.shown
                    }

                    MultiEffect {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: navigationFooterContainer.height
                        source: blurEnabled ? footerBlurSource : null
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 40
                        blurMultiplier: 0
                        autoPaddingEnabled: false
                        visible: blurEnabled && navigationFooterContainer.shown
                    }

                    Item {
                        id: navigationFooterContainer
                        readonly property bool shown: navigationFooter.shown || navbarControlsLoader.active
                        // The footer reaches the physical bottom of the screen so
                        // the footer chrome stays flush with the edge. Interactive
                        // children are pushed above the gesture/navigation inset
                        // via safeAreaBottom.
                        readonly property int safeAreaBottom: SafeArea.margins.bottom
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: (navbarControlsLoader.active ? navbarControlsLoader.height + 2 * Style.smallMargins : 0)
                                + (navigationFooter.shown ? navigationFooter.height : 0)
                                + safeAreaBottom
                        visible: shown

                        Rectangle {
                            anchors.fill: parent
                            color: Style.colors.menu_Header_Footer_Background
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            height: 1
                            color: Style.colors.menu_Header_Footer_Border
                        }

                        Loader {
                            id: navbarControlsLoader
                            anchors {
                                left: parent.left; leftMargin: Style.mediumMargins
                                right: parent.right; rightMargin: Style.mediumMargins
                                top: parent.top; topMargin: Style.mediumMargins
                            }
                            // Pages may opt in by declaring:
                            //   property Component navbarControls: Component { /* RowLayout etc. */ }
                            // The component is rendered above the tab footer and its height
                            // (plus Style.margins padding around it) is included in the page's
                            // navigationFooterHeight.
                            active: currentStackPage !== null
                                    && "navbarControls" in currentStackPage
                                    && currentStackPage.navbarControls !== null
                            sourceComponent: active ? currentStackPage.navbarControls : null
                            // When the current page reports busy, disable the navbar controls so
                            // they cannot be activated while the page-level BusyOverlay is shown.
                            enabled: !(currentStackPage !== null
                                       && "busy" in currentStackPage
                                       && currentStackPage.busy === true)
                        }

                        Item {
                            id: navigationFooter
                            readonly property bool shown: mainPage !== null
                                                          && mainPage.tabsModel !== undefined
                                                          && (mainPage.tabsModel.count > 1 || mainPage.hasConfigOverlay)
                            visible: shown
                            anchors {
                                left: parent.left; right: parent.right
                                bottom: parent.bottom; bottomMargin: navigationFooterContainer.safeAreaBottom
                            }
                            height: shown ? 58 : 0

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0
                                opacity: mainPage && mainPage.hasConfigOverlay ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                                Repeater {
                                    model: mainPage && !mainPage.hasConfigOverlay ? mainPage.tabsModel : null
                                    delegate: MainPageTabButton {
                                        required property int index
                                        required property string icon
                                        required property string name
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        checked: mainPage !== null
                                                 && currentStackPage === mainPage
                                                 && index === mainPage.currentMainViewIndex
                                        iconSource: "qrc:/icons/" + icon + ".svg"
                                        visible: mainPage ? !mainPage.isViewHidden(name) : true
                                        onClicked: {
                                            if (mainPage) {
                                                const poppedItem = _pageStack.pop(mainPage);
                                                mainPage.activateTab(index, poppedItem !== null);
                                            }
                                        }
                                        onPressAndHold: if (mainPage) mainPage.configureViews()
                                    }
                                }
                            }

                            MainPageTabButton {
                                anchors.fill: parent
                                iconSource: "qrc:/icons/configure.svg"
                                opacity: mainPage && mainPage.hasConfigOverlay ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                                visible: opacity > 0
                                checked: true
                                onClicked: if (mainPage) mainPage.toggleConfigOverlay()
                            }
                        }
                    }

                    Component.onCompleted: {
                        if (configuredHost.uuid.toString() !== "{00000000-0000-0000-0000-000000000000}") {
                            print("Configured host id is", configuredHost.uuid)

                            var cachedHost = nymeaDiscovery.nymeaHosts.find(configuredHost.uuid);
                            
                            if (cachedHost) {
                                engine.jsonRpcClient.connectToHost(cachedHost)
                                return;
                            }
                            
                            console.warn("There is a last connected host but UUID is unknown to discovery...")
                        } else if (autoConnectHost.length > 0 && index === 0) {
                            var host = nymeaDiscovery.nymeaHosts.createLanHost(Configuration.systemName, autoConnectHost);
                            engine.jsonRpcClient.connectToHost(host)

                            return;
                        } else {
                            // Only hide the splash right away if we're not trying to connect to something
                            // If it's not hidden here it will be hidden in 3 seconds or when the connection is up, whichever comes first
                            PlatformHelper.hideSplashScreen();
                        }

                        pageStack.push(Configuration.connectionWizard, StackView.Immediate)
                    }

                    Timer { running: true; repeat: false; interval: 3000; onTriggered: PlatformHelper.hideSplashScreen(); }

                    function init() {
                        print("calling init. Auth required:", engine.jsonRpcClient.authenticationRequired, "initial setup required:", engine.jsonRpcClient.initialSetupRequired, "jsonrpc connected:", engine.jsonRpcClient.connected, "Current host:", engine.jsonRpcClient.currentHost)
                        pageStack.clear()
//                        var page = pageStack.push(Qt.resolvedUrl("connection/ConnectingPage.qml"));
//                        return

                        if (!engine.jsonRpcClient.currentHost) {
                            print("pushing ConnectPage")
                            pageStack.push(Configuration.connectionWizard)
                            PlatformHelper.hideSplashScreen();
                            return;
                        }

                        if (engine.jsonRpcClient.authenticationRequired || engine.jsonRpcClient.initialSetupRequired) {
                            PlatformHelper.hideSplashScreen();
                            if (engine.jsonRpcClient.pushButtonAuthAvailable) {
                                print("opening push button auth")
                                var page = pageStack.push(Qt.resolvedUrl("PushButtonAuthPage.qml"))
                                page.backPressed.connect(function() {
                                    engine.jsonRpcClient.disconnectFromHost();
                                    init();
                                })
                                return;
                            } else {
                                if (engine.jsonRpcClient.initialSetupRequired) {
                                    var page = pageStack.push(Qt.resolvedUrl("connection/SetupWizard.qml"));
                                    page.backPressed.connect(function() {
                                        engine.jsonRpcClient.disconnectFromHost()
                                        init();
                                    })
                                    return;
                                }

                                var page = pageStack.push(Qt.resolvedUrl("connection/LoginPage.qml"));
                                page.backPressed.connect(function() {
                                    engine.jsonRpcClient.disconnectFromHost()
                                    init();
                                })
                                return;
                            }
                        }

                        if (engine.jsonRpcClient.connected) {
                            print("Connected to", engine.jsonRpcClient.currentHost.uuid, engine.jsonRpcClient.currentHost.name)
                            if (Configuration.alternativeMainPage !== "") {
                                print("Loading alternative main page:", Configuration.alternativeMainPage)
                                pageStack.push(Qt.resolvedUrl(Configuration.alternativeMainPage))
                            } else {
                                pageStack.push(Qt.resolvedUrl("MainPage.qml"))
                            }
                            return;
                        }

                        var page = pageStack.push(Qt.resolvedUrl("connection/ConnectingPage.qml"));
                        page.cancel.connect(function(){
                            engine.jsonRpcClient.disconnectFromHost();
                        })
                    }

                    function handleAndroidBackButton() {
                        // If we're connected, allow going back up to MainPage
                        if ((engine.jsonRpcClient.connected && pageStack.depth > 1)
                                // if we're not connected, only allow using the back button in wizards
                                || (!engine.jsonRpcClient.connected && pageStack.depth > 3)) {
                            pageStack.pop();
                            return true;
                        }
                        return false;
                    }

                    // New, nymea thing based push notifactions
                    function updatePushNotificationThings() {
                        if (PushNotifications.service == "") {
                            print("This platform does not support push notifications")
                            return;
                        }
                        if (!PushNotifications.token) {
                            print("No push notification token available at this time. Not updating...");
                            return;
                        }

                        var clientId = PushNotifications.clientId + "+" + Configuration.appId
                        print("Updating push notifications")
                        print("Own push service:", PushNotifications.service);
                        print("Own client ID:", clientId);
                        print("Current token:", PushNotifications.token);


                        for (var i = 0; i < engine.thingManager.things.count; i++) {
                            var thing = engine.thingManager.things.get(i);
                            if (thing.thingClass.id.toString().match(/\{?f0dd4c03-0aca-42cc-8f34-9902457b05de\}?/)) {
                                var serviceParam = thing.paramByName("service");
                                var clientIdParam = thing.paramByName("clientId")
                                var tokenParam = thing.paramByName("token")
                                print("Found a push notification thing for client id:", clientIdParam.value)
                                if (clientIdParam.value === clientId) {
                                    if (PlatformPermissions.notificationsPermission !== PlatformPermissions.PermissionStatusGranted) {
                                        PlatformPermissions.requestPermission(PlatformPermissions.PermissionNotifications)
                                    }

                                    if (tokenParam.value !== PushNotifications.token) {
                                        var params = [
                                                    { "paramTypeId": serviceParam.paramTypeId, "value": PushNotifications.service },
                                                    { "paramTypeId": clientIdParam.paramTypeId, "value": clientId },
                                                    { "paramTypeId": tokenParam.paramTypeId, "value": PushNotifications.token }
                                                ];
                                        print("Reconfiguring PushNotifications for", thing.name)
                                        engine.thingManager.reconfigureThing(thing.id, params);
                                    } else {
                                        print("Push notifications don't need to be updated. Token is valid.")
                                    }
                                }
                            }
                        }
                    }

                    Connections {
                        target: engine.jsonRpcClient
                        onCurrentHostChanged: {
                            init();
                        }
                        onVerifyConnectionCertificate: function(serverUuid, issuerInfo, pem) {
                            print("Asking user to verify certificate:", serverUuid, issuerInfo, pem)
                            var certDialogComponent = Qt.createComponent(Qt.resolvedUrl("connection/CertificateErrorDialog.qml"));
                            var popup = certDialogComponent.createObject(root);
                            popup.accepted.connect(function(){
                                engine.jsonRpcClient.acceptCertificate(serverUuid, pem);
                                engine.jsonRpcClient.connectToHost(nymeaDiscovery.nymeaHosts.find(serverUuid));
                            })
                            popup.open();
                        }
                        onConnectedChanged: {
                            print("json client connected changed", engine.jsonRpcClient.connected, engine.jsonRpcClient.serverUuid)
                            if (engine.jsonRpcClient.connected) {
                                nymeaDiscovery.cacheHost(engine.jsonRpcClient.currentHost)
                                configuredHost.uuid = engine.jsonRpcClient.serverUuid

                                for (var i = 0; i < configuredHostsModel.count; i++) {
                                    if (i != index && configuredHostsModel.get(i).uuid == engine.jsonRpcClient.serverUuid) {
                                        configuredHostsModel.removeHost(i);
                                        break;
                                    }
                                }
                            }
                            init();
                        }

                        onAuthenticationRequiredChanged: {
                            print("auth required changed")
                            init();
                        }
                        onInitialSetupRequiredChanged: {
                            print("setup required changed")
                            init();
                        }

                        onInvalidMinimumVersion: function(actualVersion, minVersion) {
                            var popup = invalidVersionComponent.createObject(app.contentItem);
                            popup.actualVersion = actualVersion;
                            popup.minVersion = minVersion;
                            popup.open()
                        }
                        onInvalidMaximumVersion: function(actualVersion, maxVersion) {
                            var popup = invalidVersionComponent.createObject(app.contentItem);
                            popup.actualVersion = actualVersion;
                            popup.maxVersion = maxVersion;
                            popup.open()
                        }
                        onInvalidServerUuid: function(uuid) {
                            var connection = engine.jsonRpcClient.currentConnection;
                            engine.jsonRpcClient.disconnectFromHost();
                            engine.jsonRpcClient.currentHost.connections.removeConnection(connection);
                            nymeaDiscovery.cacheHost(engine.jsonRpcClient.currentHost);
                        }
                    }

                    Connections {
                        target: engine.nymeaConfiguration
                        onFetchingDataChanged: {
                            print("fetching NymeaConfigration:", engine.nymeaConfiguration.fetchingData)
                            if (!engine.nymeaConfiguration.fetchingData) {
                                syncRemoteConnection()
                            }
                        }
                    }
                    Connections {
                        target: engine.nymeaConfiguration.tunnelProxyServerConfigurations
                        onCountChanged: {
                            print("tunnel proxy count changed:", engine.nymeaConfiguration.tunnelProxyServerConfigurations.count)
                            if (!engine.nymeaConfiguration.fetchingData) {
                                syncRemoteConnection();
                            }
                        }
                    }

                    function syncRemoteConnection() {
                        if (engine.jsonRpcClient.currentConnection.url.toString().startsWith("tunnel")) {
                            // Not resyncing tunnel configurations while we're connected through a tunnel ourselves
                            // (We could, maybe even should, but currently libnymea-app borrows the "NymeaHost" pointer from
                            // the hostsmodel and will crash if we delete the used Connection object)
                            return;
                        }

                        for (var i = 0; i < engine.jsonRpcClient.currentHost.connections.count; i++) {
                            var connection = engine.jsonRpcClient.currentHost.connections.get(i)
                            if (connection.url.toString().startsWith("tunnel")) {
                                console.log("Removing tunnel proxy connection:", connection.url)
                                engine.jsonRpcClient.currentHost.connections.removeConnection(i--);
                            }
                        }

                        for (var i = 0; i < engine.nymeaConfiguration.tunnelProxyServerConfigurations.count; i++) {
                            var tunnelProxyConfig = engine.nymeaConfiguration.tunnelProxyServerConfigurations.get(i);
                            console.debug("tunnelProxyConfig:", JSON.stringify(tunnelProxyConfig))
                            var url = tunnelProxyConfig.sslEnabled ? "tunnels://" : "tunnel://";
                            url += tunnelProxyConfig.address
                            url += ":" + tunnelProxyConfig.port
                            url += "?uuid=" + engine.jsonRpcClient.currentHost.uuid
                            console.info("Adding tunnel proxy connection:", url)
                            engine.jsonRpcClient.currentHost.connections.addConnection(url, Connection.BearerTypeCloud, tunnelProxyConfig.sslEnabled, "Remote proxy connection", true);
                        }
                        nymeaDiscovery.cacheHost(engine.jsonRpcClient.currentHost)
                    }

                    Connections {
                        target: Qt.application
                        enabled: engine.jsonRpcClient.connected && settings.returnToHome
                        onStateChanged: {
                            print("App active state changed:", state)
                            if (state !== Qt.ApplicationActive) {
                                init();
                            }
                        }
                    }

                    Connections {
                        target: engine.thingManager
                        onFetchingDataChanged: {
                            if (!engine.thingManager.fetchingData) {
                                processPendingPushNotificationActions();
                                updatePushNotificationThings()
                            }
                            PlatformHelper.hideSplashScreen();
                        }
                    }

                    Connections {
                        target: PlatformHelper
                        onPendingNotificationActionsChanged: {
                            processPendingPushNotificationActions()
                        }
                    }
                    function processPendingPushNotificationActions() {
                        print("pending notification actions changed:", PlatformHelper.pendingNotificationActions)
                        if (PlatformHelper.pendingNotificationActions.length > 0) {
                            var notificationAction = PlatformHelper.pendingNotificationActions[0]
                            if (notificationAction.serverUuid.replace(/[{]]/g, "") !== engine.jsonRpcClient.serverUuid.toString().replace(/[{}]/g, "")) {
                                print("notification action for different server")
                                return;
                            }
                            print("handling action", JSON.stringify(notificationAction))

                            if (notificationAction.dataMap.hasOwnProperty("open")) {
                                // It could be just a thing ID
                                var target = notificationAction.dataMap["open"]
                                var thing = engine.thingManager.things.getThing(target)
                                if (thing) {
                                    print("opening thing:", thing.name)
                                    pageStack.push("/ui/devicepages/" + NymeaUtils.interfaceListToDevicePage(thing.thingClass.interfaces), {thing: thing})
                                } else {
                                    // or a view name
                                    console.log("going to main view:", target)
                                    pageStack.currentItem.goToView(target, notificationAction.dataMap)
                                }
                            }

                            if (notificationAction.dataMap.hasOwnProperty("execute")) {
                                var action = notificationAction.dataMap["execute"]
                                var thingId = notificationAction.dataMap["thingId"]
                                var actionParams = JSON.parse(notificationAction.dataMap["actionParams"])
                                print("executing:", thingId, action, actionParams)
                                engine.thingManager.things.getThing(thingId).executeAction(action, actionParams);
                            }


                            PlatformHelper.notificationActionHandled(notificationAction.id)
                        }
                    }


                    Component {
                        id: invalidVersionComponent
                        Popup {
                            id: popup

                            property string actualVersion: ""
                            property string minVersion: ""
                            property string maxVersion: ""

                            width: app.width * .8
                            height: col.childrenRect.height + app.margins * 2
                            x: (app.width - width) / 2
                            y: (app.height - height) / 2
                            visible: false
                            ColumnLayout {
                                id: col
                                anchors { left: parent.left; right: parent.right }
                                spacing: app.margins
                                Label {
                                    text: qsTr("Connection error")
                                    Layout.fillWidth: true
                                    font.pixelSize: app.largeFont
                                }
                                Label {
                                    text: popup.minVersion != ""
                                          ? qsTr("The version of the %1 system you are trying to connect to is too old. This app requires at least API version %2 but this %1 system only supports API version %3. Please update your %1 system.").arg(Configuration.systemName).arg(popup.minVersion).arg(popup.actualVersion)
                                          : qsTr("The version of the %1 system you are trying to connect to is too new. This app supports only up to API version %2 but this %1 system provides API version %3. Please update %4.").arg(Configuration.systemName).arg(popup.maxVersion).arg(popup.actualVersion).arg(Configuration.appName)
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                Button {
                                    Layout.fillWidth: true
                                    text: qsTr("OK")
                                    onClicked: {
                                        engine.jsonRpcClient.disconnectFromHost();
                                        popup.close()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
