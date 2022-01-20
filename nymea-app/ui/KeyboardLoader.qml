/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2020, nymea GmbH
* Contact: contact@nymea.io
*
* This file is part of nymea.
* This project including source code and documentation is protected by
* copyright law, and remains the property of nymea GmbH. All rights, including
* reproduction, publication, editing and translation, are reserved. The use of
* this project is subject to the terms of a license agreement to be concluded
* with nymea GmbH in accordance with the terms of use of nymea GmbH, available
* under https://nymea.io/license
*
* GNU General Public License Usage
* Alternatively, this project may be redistributed and/or modified under the
* terms of the GNU General Public License as published by the Free Software
* Foundation, GNU version 3. This project is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along with
* this project. If not, see <https://www.gnu.org/licenses/>.
*
* For any further details and any questions please contact us under
* contact@nymea.io or see our FAQ/Licensing Information on
* https://nymea.io/license/faq
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

import QtQuick 2.4
import QtQuick.Window 2.15
import Nymea 1.0

Item {
    id: root

    implicitHeight: d.active
                    ? d.kbd.height
                    : Qt.inputMethod.visible
                      ? Math.max(0, Qt.inputMethod.keyboardRectangle.height) / Screen.devicePixelRatio
                      : 0

    Behavior on implicitHeight { NumberAnimation { duration: Style.animationDuration; easing.type: Easing.InOutQuad } }

    QtObject {
        id: d
        property bool active: d.kbd && d.kbd.active
        property var kbd: null
        property string virtualKeyboardString:
            '
            import QtQuick 2.8;
            import QtQuick.VirtualKeyboard 2.1
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
