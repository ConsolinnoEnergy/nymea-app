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

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Nymea 1.0

Item {
    id: root
    implicitHeight: size * 4
    implicitWidth: size * 7

    property Thing thing: null
    readonly property State openState: thing.stateByName("state")
    readonly property bool canStop: thing && thing.thingClass.actionTypes.findByName("stop")

    property bool invert: false
    property bool backgroundEnabled: false
    property int size: Style.iconSize

    signal activated(string button);

    RowLayout {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 0

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        ProgressButton {
            imageSource: root.invert ? "qrc:/icons/down.svg" : "qrc:/icons/up.svg"
            backgroundColor: root.backgroundEnabled ? Style.green : "transparent"
            color:  root.backgroundEnabled ? Style.white : Style.iconColor
            size: root.size
            busy: root.openState ? root.openState.value === "opening" : openBusyTimer.running
            onClicked: {
                engine.thingManager.executeAction(root.thing.id, root.thing.thingClass.actionTypes.findByName("open").id)
                root.activated("open")
                openBusyTimer.start()
                closeBusyTimer.stop()
            }

            Timer {
                id: openBusyTimer
                interval: 5000
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        ProgressButton {
            visible: root.canStop
            backgroundColor: root.backgroundEnabled ? Style.yellow : "transparent"
            color:  root.backgroundEnabled ? Style.white : Style.iconColor
            size: root.size
            imageSource: "qrc:/icons/media-playback-stop.svg"
            onClicked: {
                engine.thingManager.executeAction(root.thing.id, root.thing.thingClass.actionTypes.findByName("stop").id)
                root.activated("stop")
                openBusyTimer.stop()
                closeBusyTimer.stop()
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }

        ProgressButton {
            imageSource: root.invert ? "qrc:/icons/up.svg" : "qrc:/icons/down.svg"
            backgroundColor: root.backgroundEnabled ? Style.red : "transparent"
            color:  root.backgroundEnabled ? Style.white : Style.iconColor
            size: root.size
            busy: root.openState ? root.openState.value === "closing" : closeBusyTimer.running
            onClicked: {
                engine.thingManager.executeAction(root.thing.id, root.thing.thingClass.actionTypes.findByName("close").id)
                root.activated("close")
                openBusyTimer.stop();
                closeBusyTimer.start()
            }
            Timer {
                id: closeBusyTimer
                interval: 5000
            }
        }

        Item { Layout.fillWidth: true; Layout.fillHeight: true }
    }
}

