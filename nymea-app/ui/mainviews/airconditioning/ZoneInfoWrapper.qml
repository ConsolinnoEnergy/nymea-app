/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2022, nymea GmbH
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

import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.2
import QtGraphicalEffects 1.0
import QtCharts 2.2
import Nymea 1.0
import Nymea.AirConditioning 1.0
import "qrc:/ui/components"
import "qrc:/ui/delegates"

Item {
    id: root

    property ZoneInfo zone: null

    readonly property ThingsProxy thermostats: ThingsProxy {
        engine: zone.thermostats.length > 0 ? _engine : null
        shownThingIds: zone.thermostats
    }
    readonly property ThingsProxy heatingThermostats: ThingsProxy {
        engine: _engine
        parentProxy: thermostats
        stateFilter: { "heatingOn": true }
    }
    readonly property ThingsProxy coolingThermostats: ThingsProxy {
        engine: _engine
        parentProxy: thermostats
        stateFilter: { "coolingOn": true }
    }

    readonly property ThingsProxy windowSensors: ThingsProxy {
        engine: zone.windowSensors.length > 0 ? _engine : null
        shownThingIds: zone.windowSensors
    }
    readonly property ThingsProxy openWindows: ThingsProxy {
        engine: _engine
        parentProxy: windowSensors
        stateFilter: { "closed": false }
    }

    readonly property ThingsProxy indoorSensors: ThingsProxy {
        engine: root.zone.indoorSensors.length > 0 ? _engine : null
        shownThingIds: root.zone.indoorSensors
    }
    readonly property ThingsProxy indoorTempSensors: ThingsProxy {
        engine: _engine
        parentProxy: indoorSensors
        shownInterfaces: ["temperaturesensor"]
    }
    readonly property ThingsProxy indoorHumiditySensors: ThingsProxy {
        engine: _engine
        parentProxy: indoorSensors
        shownInterfaces: ["humiditysensor"]
    }
    readonly property ThingsProxy indoorVocSensors: ThingsProxy {
        engine: _engine
        parentProxy: indoorSensors
        shownInterfaces: ["vocsensor"]
    }
    readonly property ThingsProxy indoorPm25Sensors: ThingsProxy {
        engine: _engine
        parentProxy: indoorSensors
        shownInterfaces: ["pm25sensor"]
    }

    readonly property ThingsProxy outdoorSensors: ThingsProxy {
        engine: root.zone.outdoorSensors.length > 0 ? _engine : null
        shownThingIds: root.zone.outdoorSensors
    }
    readonly property ThingsProxy outdoorTempSensors: ThingsProxy {
        engine: _engine
        parentProxy: outdoorSensors
        shownInterfaces: ["temperaturesensor"]
    }
    readonly property ThingsProxy outoorHumiditySensors: ThingsProxy {
        engine: _engine
        parentProxy: outdoorSensors
        shownInterfaces: ["humiditysensor"]
    }
    readonly property ThingsProxy outdoorPm25Sensors: ThingsProxy {
        engine: _engine
        parentProxy: outdoorSensors
        shownInterfaces: ["pm25sensor"]
    }

    readonly property ThingsProxy notifications: ThingsProxy {
        engine: root.zone.notifications.length > 0 ? _engine : null
        shownThingIds: root.zone.notifications
    }
}
