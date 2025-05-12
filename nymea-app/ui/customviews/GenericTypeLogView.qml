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

import QtQuick 2.5
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Nymea 1.0
import "../components"

Item {
    id: root

    signal addRuleClicked(int index)

    property var logsModel: null

    property alias delegate: listView.delegate

    ListView {
        id: listView
        anchors.fill: parent
        model: logsModel
        clip: true

        ScrollBar.vertical: ScrollBar {}

        SwipeDelegateGroup {}

        delegate: NymeaSwipeDelegate {
            id: logEntryDelegate
            width: parent.width
            implicitHeight: app.delegateHeight
            property Thing thing: engine.thingManager.things.getThing(model.thingId)
            property ThingClass thingClass: engine.thingManager.thingClasses.getThingClass(thing.thingClassId)
            iconName: "qrc:/icons/event.svg"
            text: Qt.formatDateTime(model.timestamp,"dd.MM.yy - hh:mm:ss")
            subText: thingClass.eventTypes.getEventType(model.typeId).displayName + (model.value.length > 0 ? (": " + model.value.trim()) : "")
            prominentSubText: true
            progressive: false
            contextOptions: [
                {
                    text: qsTr("Magic"),
                    icon: "qrc:/icons/magic.svg",
                    callback: function() { root.addRuleClicked(index) }
                }
            ]
            onClicked: {
                if (swipe.complete) {
                    swipe.close()
                } else {
                    swipe.open(SwipeDelegate.Right)
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            visible: root.logsModel.busy
            running: visible
        }
    }
}
