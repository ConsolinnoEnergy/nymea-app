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
import QtQuick.Window
import QtCore
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Nymea

import "components"
import "delegates"
import "mainviews"

Page {
    id: root

    // Removing the background from this page only because the MainViewBase adds it again in
    // a deepter layer as we need to include it in the blurring of the header and footer.
    // We don't want to paint the background on the entire screen twice (overdraw is costly)
    background: null
    bottomPadding: 0  // footer lives at RootItem level; main views handle spacing themselves

    // Footer lives at RootItem level; MainPage receives its height here so views can adjust bottomMargin.
    property int navigationFooterHeight: 0

    // Properties exposed for the RootItem-level navigation footer
    property alias tabsModel: filteredContentModel
    property alias currentMainViewIndex: swipeView.currentIndex
    readonly property bool hasConfigOverlay: d.configOverlay !== null

    function isViewHidden(name) { return d.isHiddenView(name); }

    function toggleConfigOverlay() {
        if (d.configOverlay) {
            d.configOverlay.destroy()
            d.configOverlay = null
        } else {
            configureViews()
        }
    }

    // Switch to a tab by index, suppressing animation when coming from a hidden view.
    function activateTab(index, immediate) {
        if (d.isHiddenView(filteredContentModel.modelData(swipeView.currentIndex, "name")) ||
                immediate) {
            setSwipeViewIndexWithoutAnimation(index);
        } else {
            swipeView.currentIndex = index;
        }
    }

    function configureViews() {
        if (Configuration.hasOwnProperty("mainViewsFilter")) {
            console.warn("Main views configuration is disabled by app configuration")
            return
        }

        PlatformHelper.vibrate(PlatformHelper.HapticsFeedbackSelection)
        d.configOverlay = configComponent.createObject(contentContainer)
    }

    function goToView(viewName, data, immediate) {
        // We allow separating the target by : and pass more stuff to
        console.log("Going to main view", viewName, filteredContentModel.count, data)
        for (var i = 0; i < filteredContentModel.count; i++) {
            console.log("got", i, filteredContentModel.modelData(i, "name"))
            if (filteredContentModel.modelData(i, "name") === viewName) {
                console.log("activating", i)
//                mainViewSettings.currentIndex = i;
//                tabBar.currentIndex = i;
                if (immediate) {
                    setSwipeViewIndexWithoutAnimation(i);
                } else {
                    swipeView.setCurrentIndex(i)
                }
                swipeView.currentItem.item.handleEvent(data)
                break;
            }
        }
    }

    function setSwipeViewIndexWithoutAnimation(index) {
        if (swipeView.contentItem && swipeView.contentItem.hasOwnProperty("highlightMoveDuration")) {
            const old = swipeView.contentItem.highlightMoveDuration;
            swipeView.contentItem.highlightMoveDuration = 0;
            swipeView.currentIndex = index;
            swipeView.contentItem.highlightMoveDuration = old;
        } else {
            swipeView.currentIndex = index;
        }
    }

    header: Item {
        id: mainHeader
        height: 0
        // HeaderButton {
        //     id: menuButton
        //     imageSource: "qrc:/icons/menu.svg"
        //     anchors {
        //         left: parent.left
        //         top: parent.top
        //         topMargin: Style.smallMargins
        //     }

        //     onClicked: {
        //         if (d.configOverlay != null) {
        //             d.configOverlay.destroy();
        //         }
        //         app.mainMenu.open()
        //     }
        // }
        RoundButton {
            id: menuButton
            icon.source: "qrc:/icons/menu.svg"
            flat: true
            anchors {
                left: parent.left
                leftMargin: Style.smallMargins
                top: parent.top
                topMargin: Style.smallMargins
            }

            onClicked: {
                if (d.configOverlay != null) {
                    d.configOverlay.destroy();
                    d.configOverlay = null
                }
                app.mainMenu.open()
            }
        }

        Image {
            id: mainHeaderLogo
            source: "qrc:/styles/%1/logo-wide.svg".arg(styleController.currentStyle)
            anchors {
                top: parent.top;
                topMargin: (contentContainer.headerSize - height) / 2
                right: parent.right
                rightMargin: Style.margins
            }
            fillMode: Image.PreserveAspectFit
            height: 28
            sourceSize.height: height
            antialiasing: true
        }

        Row {
            id: additionalIcons
            anchors { right: parent.right; top: parent.top }
            visible: !d.configOverlay
            width: visible ? implicitWidth : 0

            HeaderButton {
                id: button
                imageSource: "qrc:/icons/system-update.svg"
                color: Style.accentColor
                visible: updatesModel.count > 0 || engine.systemController.updateRunning
                onClicked: pageStack.push(Qt.resolvedUrl("system/SystemUpdatePage.qml"))
                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 2000
                    loops: Animation.Infinite
                    running: engine.systemController.updateRunning
                    onStopped: button.rotation = 0;
                }
                PackagesFilterModel {
                    id: updatesModel
                    packages: engine.systemController.packages
                    updatesOnly: true
                }
            }
            Repeater {
                model: swipeView.currentItem != null && swipeView.currentItem.item.hasOwnProperty("headerButtons") ? swipeView.currentItem.item.headerButtons : 0
                delegate: HeaderButton {
                    imageSource: swipeView.currentItem.item.headerButtons[index].iconSource
                    onClicked: swipeView.currentItem.item.headerButtons[index].trigger()
                    visible: swipeView.currentItem.item.headerButtons[index].visible
                    color: swipeView.currentItem.item.headerButtons[index].color
                }
            }
        }

        Rectangle {
            anchors {
                right: parent.right
                left: parent.left
                top: parent.top
                topMargin: contentContainer.headerSize - 1
            }
            height: 1
            color: Style.colors.menu_Header_Footer_Border
        }
    }

    Connections {
        target: engine.ruleManager
        onAddRuleReply: (commandId, ruleError, ruleId) => {
            d.editRulePage.busy = false
            if (d.editRulePage) {
                pageStack.pop();
                d.editRulePage = null
            }
        }
    }
    QtObject {
        id: d
        property bool blurEnabled: PlatformHelper.deviceManufacturer !== "raspbian"
        property var editRulePage: null
        property var configOverlay: null

        function isHiddenView(name) {
            if (!Configuration.hasOwnProperty("hiddenMainViews")) { return false; }
            return Configuration.hiddenMainViews.indexOf(name) >= 0;
        }
    }

    Settings {
        id: mainViewSettings
        category: engine.jsonRpcClient.currentHost.uuid
        property string mainMenuContent: ""
        property var sortOrder: []
        // Priority for main view config:
        // 1. Settings made by the user
        // 2. Style mainViewsFilter as that comes with branding (for now, if a style defines main views, all of them are active by default)
        // 3. Command line args
        // 4. Just show "things" alone by default
        property var filterList: Configuration.hasOwnProperty("mainViewsFilter") ?
                                     Configuration.mainViewsFilter
                                   : defaultMainViewFilter.length > 0 ?
                                         defaultMainViewFilter.split(',')
                                       : Configuration.defaultMainViews
        property int currentIndex: 0

        onFilterListChanged: {
            if (filterList.indexOf("consolinno") >= 0) {
                filterList = ["consolinnoDashboard", "consolinnoStats"];
            }
        }

        onSortOrderChanged: {
            if (sortOrder.indexOf("consolinno") >= 0) {
                const newSortOrder = [];
                newSortOrder.push("consolinnoDashboard");
                newSortOrder.push("consolinnoStats");
                for (let i = 0; i < sortOrder.length; ++i) {
                    const entry = sortOrder[i];
                    if (entry !== "consolinno") {
                        newSortOrder.push(entry);
                    }
                }
                sortOrder = newSortOrder;
            }
        }
    }

    ListModel {
        id: mainMenuBaseModel
        ListElement { name: "things"; source: "ThingsView"; displayName: qsTr("Things"); icon: "things"; minVersion: "0.0" }
        ListElement { name: "favorites"; source: "FavoritesView"; displayName: qsTr("Favorites"); icon: "starred"; minVersion: "2.0" }
        ListElement { name: "groups"; source: "GroupsView"; displayName: qsTr("Groups"); icon: "groups"; minVersion: "2.0" }
        ListElement { name: "scenes"; source: "ScenesView"; displayName: qsTr("Scenes"); icon: "slideshow"; minVersion: "2.0" }
        ListElement { name: "garages"; source: "GaragesView"; displayName: qsTr("Garages"); icon: "garage/garage-100"; minVersion: "2.0" }
        ListElement { name: "energy"; source: "EnergyView"; displayName: qsTr("Energy"); icon: "smartmeter"; minVersion: "2.0" }
        ListElement { name: "media"; source: "MediaView"; displayName: qsTr("Media"); icon: "media"; minVersion: "2.0" }
        ListElement { name: "dashboard"; source: "DashboardView"; displayName: qsTr("Dashboard"); icon: "dashboard"; minVersion: "5.5" }
        ListElement { name: "airconditioning"; source: "AirConditioningView"; displayName: qsTr("AC"); icon: "sensors"; minVersion: "6.2" }
    }

    ListModel {
        id: mainMenuModel
        ListElement { name: "dummy"; source: "Dummy"; displayName: ""; icon: "" }

        Component.onCompleted: {
            var configList = {}
            var newList = {}
            var newItems = 0
            var hiddenList = []

            // Add extra views first to make them appear first in the list unless the config says otherwise
            if (Configuration.hasOwnProperty("additionalMainViews")) {
                for (var i = 0; i < Configuration.additionalMainViews.count; i++) {
                    var item = Configuration.additionalMainViews.get(i);
                    if (d.isHiddenView(item.name)) {
                        hiddenList.push(item);
                        continue;
                    }
                    var idx = mainViewSettings.sortOrder.indexOf(item.name);
                    if (idx === -1) {
                        newList[newItems++] = item;
                    } else {
                        configList[idx] = item;
                    }
                }
            }


            for (var i = 0; i < mainMenuBaseModel.count; i++) {
                var item = mainMenuBaseModel.get(i);
                if (!engine.jsonRpcClient.ensureServerVersion(item.minVersion)) {
                    console.log("Skipping main view", item.name, "as the minimum required server version isn't met:", engine.jsonRpcClient.jsonRpcVersion, "<", item.minVersion)
                    continue;
                }

                var idx = mainViewSettings.sortOrder.indexOf(item.name);
                if (idx === -1) {
                    newList[newItems++] = item;
                } else {
                    configList[idx] = item;
                }
            }
            clear();

            var brandingFilter = Configuration.hasOwnProperty("mainViewsFilter") ? Configuration.mainViewsFilter : []

            for (idx in configList) {
                item = configList[idx];
                if (brandingFilter.length === 0 || brandingFilter.indexOf(item.name) >= 0) {
                    mainMenuModel.append(item)
                }
            }
            for (idx  in newList) {
                item = newList[idx];
                if (brandingFilter.length === 0 || brandingFilter.indexOf(item.name) >= 0) {
                    mainMenuModel.append(item)
                }
            }
            // Hidden views always go last and are never subject to branding filter or sort order
            for (var i = 0; i < hiddenList.length; i++) {
                mainMenuModel.append(hiddenList[i]);
            }

            let startViewIndex = 0;
            for (let i = 0; i < mainMenuModel.count; i++) {
                let item = mainMenuModel.get(i);
                if (mainViewSettings.filterList.indexOf(item.name) === -1) { continue; }
                if (item.name === "consolinnoDashboard") { break; }
                ++startViewIndex;
            }

            swipeView.currentIndex = startViewIndex;
            mainViewSettings.currentIndex = Qt.binding(function() { return swipeView.currentIndex; })
        }
    }

    SortFilterProxyModel {
        id: filteredContentModel
        sourceModel: mainMenuModel
        filterList: {
            var list = mainViewSettings.filterList.slice();
            if (Configuration.hasOwnProperty("hiddenMainViews")) {
                list = list.concat(Configuration.hiddenMainViews);
            }
            return list;
        }
        filterRoleName: "name"
    }


    Item {
        id: contentContainer
        anchors.fill: parent
        clip: true

        property int headerSize: 64
        property int footerSize: 58

        readonly property int scrollOffset: swipeView.currentItem ? swipeView.currentItem.item.contentY : 0
        readonly property int headerBlurSize: Math.min(headerSize, scrollOffset * 2)

        Background {
            anchors.fill: parent
        }

        SwipeView {
            id: swipeView
            anchors.fill: parent
            opacity: d.configOverlay === null ? 1 : 0
            visible: !engine.thingManager.fetchingData
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

            Repeater {
                id: mainViewsRepeater
                model: d.configOverlay != null ? null : filteredContentModel

                delegate: Loader {
                    id: mainViewLoader
                    width: swipeView.width
                    height: swipeView.height
                    clip: true
                    source: "mainviews/" + model.source + ".qml"
                    visible: SwipeView.isCurrentItem || SwipeView.isNextItem || SwipeView.isPreviousItem

                    Binding {
                        target: mainViewLoader.item
                        property: "isCurrentItem"
                        value: swipeView.currentIndex == index
                    }

                    Binding {
                        target: mainViewLoader.item
                        property: "bottomMargin"
                        value: root.navigationFooterHeight
                    }
                }
            }
        }


        ColumnLayout {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Style.margins }
            spacing: Style.margins
            visible: engine.thingManager.fetchingData
            BusyIndicator {
                Layout.alignment: Qt.AlignHCenter
                running: parent.visible
            }
            Label {
                text: qsTr("Loading data...")
                font: Style.bigFont
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    ShaderEffectSource {
        id: headerBlurSource
        width: contentContainer.width
        height: d.configOverlay ? contentContainer.headerSize : contentContainer.headerBlurSize
        sourceItem: d.blurEnabled ? contentContainer : null
        sourceRect: Qt.rect(0, 0, contentContainer.width, d.configOverlay ? contentContainer.headerSize : contentContainer.headerBlurSize)
        visible: false
    }

    FastBlur {
        anchors {
            left: parent.left;
            top: parent.top;
            right: parent.right;
        }
        height: d.configOverlay ? contentContainer.headerSize : contentContainer.headerBlurSize
        radius: 40
        transparentBorder: false
        source: d.blurEnabled ? headerBlurSource : null
        visible: d.blurEnabled
    }

    Rectangle {
        id: headerOpacityMask
        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
        }
        height: d.configOverlay ? contentContainer.headerSize : contentContainer.headerBlurSize
        color: Style.colors.menu_Header_Footer_Background
    }

    Component {
        id: configComponent
        Background {
            id: configOverlay
            width: contentContainer.width
            height: contentContainer.height

            ListView {
                id: configListView
                anchors.fill: parent
                model: mainMenuModel
                topMargin: contentContainer.headerSize
                bottomMargin: contentContainer.footerSize

                property bool dragging: draggingIndex >= 0
                property int draggingIndex : -1

                moveDisplaced: Transition { NumberAnimation { properties: "y" } }

                delegate: NymeaItemDelegate {
                    id: viewConfigDelegate
                    width: parent.width
                    text: model.displayName
                    iconName: Qt.resolvedUrl("qrc:/icons/" + model.icon + ".svg")
                    progressive: false
                    checked: mainViewSettings.filterList.indexOf(model.name) >= 0
                    visible: !d.isHiddenView(model.name) && index !== configListView.draggingIndex
                    additionalItem: CheckBox {
                        checked: viewConfigDelegate.checked
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            var newList = []
                            for (var i = 0; i < mainMenuModel.count; i++) {
                                var entry = mainMenuModel.get(i).name;
                                if (entry === model.name) {
                                    if (!isEnabled) {
                                        newList.push(model.name)
                                    }
                                } else {
                                    if (mainViewSettings.filterList.indexOf(entry) >= 0) {
                                        newList.push(entry)
                                    }
                                }
                            }
                            if (newList.length === 0) {
                                newList = Configuration.defaultMainView
                            }

                            mainViewSettings.filterList = newList
                        }
                    }
                }

                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    preventStealing: configListView.dragging
                    property int dragOffset: 0

                    onPressAndHold: {
                        mouse.accepted = true
                        var mouseYInListView = configListView.contentItem.mapFromItem(dndArea, mouseX, mouseY).y;
                        configListView.draggingIndex = configListView.indexAt(mouseX, mouseYInListView)
                        var item = mainMenuModel.get(configListView.draggingIndex)
                        print("draggingIndex", configListView.draggingIndex)
                        dndItem.text = item.displayName
                        dndItem.iconName = item.icon
                        var visualItem = configListView.itemAt(mouseX, mouseYInListView)
                        dndItem.checked = visualItem.checked
                        dndArea.dragOffset = configListView.mapToItem(visualItem, mouseX, mouseY).y
                        PlatformHelper.vibrate(PlatformHelper.HapticsFeedbackImpact)
                    }
                    onMouseYChanged: {
                        if (configListView.dragging) {
                            var mouseYInListView = configListView.contentItem.mapFromItem(dndArea, mouseX, mouseY).y;
                            var indexUnderMouse = configListView.indexAt(mouseX, mouseYInListView - dndArea.dragOffset / 2)
                            if (indexUnderMouse < 0) {
                                return;
                            }

                            indexUnderMouse = Math.min(Math.max(0, indexUnderMouse), configListView.count - 1)
                            if (configListView.draggingIndex !== indexUnderMouse) {
                                print("moving to", indexUnderMouse)
                                PlatformHelper.vibrate(PlatformHelper.HapticsFeedbackSelection)
                                mainMenuModel.move(configListView.draggingIndex, indexUnderMouse, 1)
                                configListView.draggingIndex = indexUnderMouse;
                            }
                        }
                    }
                    onReleased: {
                        print("released!")
                        var mouseYInListView = configListView.contentItem.mapFromItem(dndArea, mouseX, mouseY).y;
                        var clickedIndex = configListView.indexAt(mouseX, mouseYInListView)
                        var item = mainMenuModel.get(clickedIndex)
                        var isEnabled = mainViewSettings.filterList.indexOf(item.name) >= 0;
                        if (!configListView.dragging) {
                            var newList = []
                            for (var i = 0; i < mainMenuModel.count; i++) {
                                var entry = mainMenuModel.get(i).name;
                                if (entry === item.name) {
                                    if (!isEnabled) {
                                        newList.push(item.name)
                                    }
                                } else {
                                    if (mainViewSettings.filterList.indexOf(entry) >= 0) {
                                        newList.push(entry)
                                    }
                                }
                            }
                            if (newList.length === 0) {
                                newList = Configuration.defaultMainView
                            }

                            mainViewSettings.filterList = newList
                        }
                        configListView.draggingIndex = -1;

                        var newSortOrder = []
                        for (var i = 0; i < mainMenuModel.count; i++) {
                            newSortOrder.push(mainMenuModel.get(i).name)
                        }
                        mainViewSettings.sortOrder = newSortOrder;
                    }
                }

                NymeaItemDelegate {
                    id: dndItem
                    visible: configListView.dragging
                    y: dndArea.mouseY - dndArea.dragOffset
                    width: configListView.width
                    progressive: false
                    additionalItem: CheckBox {
                        checked: dndItem.checked
                        anchors.verticalCenter: parent.verticalCenter
                    }

                }
            }
        }
    }
}
