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
import Nymea

Page {
    id: root
    header: null

    // Header configuration knobs. Derived pages should set these instead of
    // overriding the header slot.
    property alias coHeader: coHeader
    property string headerText: root.title
    property bool headerBackButtonVisible: true
    property bool headerMenuButtonVisible: false
    // Optional. Extra item placed after the title inside the header (e.g. a
    // quick-action RoundButton).
    property Component headerExtras: null
    signal backPressed()
    signal menuPressed()
    onBackPressed: pageStack.pop()

    CoHeader {
        id: coHeader
        anchors { left: parent.left; right: parent.right; top: parent.top }
        z: 1
        blurSource: flickable
        text: root.headerText
        backButtonVisible: root.headerBackButtonVisible
        menuButtonVisible: root.headerMenuButtonVisible
        onBackPressed: root.backPressed()
        onMenuPressed: root.menuPressed()

        Loader {
            active: root.headerExtras !== null
            sourceComponent: root.headerExtras
        }
    }

    default property alias content: contentColumn.data
    property alias busy: busyOverlay.shown
    property alias busyText: busyOverlay.text

    // Page lives behind the navigation footer in RootItem so the footer's
    // blur effect has real content to sample. RootItem propagates its
    // footer height into this property; we use it for scroll clearance only.
    property int navigationFooterHeight: 0

    // Opt out of the style-level bottomPadding (58 px). We render the
    // Flickable across the full page area instead, and add the footer
    // height to contentHeight so the last item can be scrolled above
    // the footer. This makes the footer's blur work on sub-pages.
    bottomPadding: 0

    BackgroundFocusHandler { anchors.fill: parent }

    background: Rectangle { color: Style.backgroundColor }

    Flickable {
        id: flickable
        anchors.fill: parent
        topMargin: coHeader.height
        contentHeight: contentColumn.height + Style.margins + root.navigationFooterHeight
        clip: true

        ScrollBar.vertical: ScrollBar {}

        // Flickable's default contentY is 0, which would show the first
        // contentHeight pixels of content behind the header. Snap to the
        // topMargin position so the page opens with content visible just
        // below the header.
        Component.onCompleted: Qt.callLater(() => contentY = -topMargin)
        Connections {
            target: coHeader
            function onHeightChanged() {
                if (flickable.contentY > -coHeader.height && flickable.contentY <= 0) {
                    flickable.contentY = -coHeader.height
                }
            }
        }

        // When the keyboard is visible, the Flickable shrinks via a 130 ms
        // animation on KeyboardLoader.implicitHeight. React to heightChanged
        // (fired throughout the animation) so the focused item is scrolled
        // into view as soon as the viewport is small enough to obscure it.
        onHeightChanged: {
            if (PlatformHelper.imeHeight <= 0)
                return
            var focused = Window.activeFocusItem
            if (!focused)
                return
            var itemBottom = focused.mapToItem(contentColumn, 0, focused.height).y
            var visibleBottom = flickable.contentY + flickable.height
            if (itemBottom > visibleBottom) {
                flickable.contentY = itemBottom - flickable.height + Style.margins
            }
        }

        ColumnLayout {
            id: contentColumn
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(500, flickable.width)
        }
    }

    BusyOverlay {
        id: busyOverlay
    }
}
