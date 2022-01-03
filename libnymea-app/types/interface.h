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

#ifndef INTERFACE_H
#define INTERFACE_H

#include <QObject>

#include "eventtypes.h"
#include "statetypes.h"
#include "actiontypes.h"

class ThingClass;

class Interface : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString displayName READ displayName CONSTANT)
    Q_PROPERTY(EventTypes* eventTypes READ eventTypes CONSTANT)
    Q_PROPERTY(StateTypes* stateTypes READ stateTypes CONSTANT)
    Q_PROPERTY(ActionTypes* actionTypes READ actionTypes CONSTANT)

public:
    explicit Interface(const QString &name, const QString &displayName, QObject *parent = nullptr);

    QString name() const;
    QString displayName() const;
    EventTypes* eventTypes() const;
    StateTypes* stateTypes() const;
    ActionTypes* actionTypes() const;

    ThingClass* createThingClass();

private:
    QString m_name;
    QString m_displayName;
    EventTypes* m_eventTypes = nullptr;
    StateTypes* m_stateTypes = nullptr;
    ActionTypes* m_actionTypes = nullptr;
};

#endif // INTERFACE_H
