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
import QtQuick.Window
import Nymea

Item {
    id: root
    implicitHeight: d.active
                    ? d.kbd.height
                    : Qt.platform.os === "ios"
                        // On iOS PlatformHelperIOS observes the UIKit keyboard
                        // notifications and reports an authoritative imeHeight
                        // (in device independent pixels). Prefer it over
                        // Qt.inputMethod.keyboardRectangle, which is unreliable
                        // there: it reports 0 for some keyboards (e.g. the
                        // numeric pad, hiding the Quick-Nav bar) and an oversized
                        // rectangle on newer iOS versions (leaving a gap between
                        // the content and the keyboard).
                        ? PlatformHelper.imeHeight
                        : Math.max(
                            PlatformHelper.imeHeight,
                            Qt.inputMethod.visible
                                ? Math.max(0, Qt.inputMethod.keyboardRectangle.height / Screen.devicePixelRatio)
                                : 0
                          )


    Behavior on implicitHeight { NumberAnimation { duration: 130; easing.type: Easing.InOutQuad } }

    // Provides the (translated) label for the iOS numeric-keyboard dismiss bar.
    // Bound rather than assigned once so it follows runtime language changes.
    // Ignored on platforms that don't show such a bar.
    Binding {
        target: PlatformHelper
        property: "imeActionButtonText"
        value: qsTr("Ok")
    }

    // Neutral focus target. Numeric keyboards on iOS have no return key, so the
    // native accessory bar's button drives this: we move focus away from the
    // text field (so Qt does not immediately reopen the keyboard) and then hide
    // the input panel - mirroring BackgroundFocusHandler's dismiss idiom.
    Item { id: focusSink }

    Connections {
        target: PlatformHelper
        function onImeActionTriggered() {
            focusSink.forceActiveFocus()
            Qt.inputMethod.hide()
        }
    }

    QtObject {
        id: d
        property bool active: d.kbd && d.kbd.active
        property var kbd: null
        property string virtualKeyboardString:
            '
            import QtQuick
            import QtQuick.VirtualKeyboard
            InputPanel {
                id: inputPanel
                y: Qt.inputMethod.visible ? parent.height - inputPanel.height : parent.height
                anchors.left: parent.left
                anchors.right: parent.right
            }
            '
    }


    Component.onCompleted: {
        if (useVirtualKeyboard) {
            d.kbd = Qt.createQmlObject(d.virtualKeyboardString, root);
        }
    }
}
