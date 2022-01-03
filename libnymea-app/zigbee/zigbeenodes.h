/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2021, nymea GmbH
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

#ifndef ZIGBEENODES_H
#define ZIGBEENODES_H

#include <QObject>
#include <QAbstractListModel>

#include "zigbeenode.h"

class ZigbeeNodes : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        RoleNetworkUuid,
        RoleIeeeAddress,
        RoleNetworkAddress,
        RoleType,
        RoleState,
        RoleManufacturer,
        RoleModel,
        RoleVersion,
        RoleRxOnWhenIdle,
        RoleReachable,
        RoleLqi,
        RoleLastSeen
    };
    Q_ENUM(Roles)

    explicit ZigbeeNodes(QObject *parent = nullptr);
    virtual ~ZigbeeNodes() override = default;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void addNode(ZigbeeNode *node);
    void removeNode(const QString &ieeeAddress);

    void clear();

    Q_INVOKABLE virtual ZigbeeNode *get(int index) const;
    Q_INVOKABLE ZigbeeNode *getNode(const QString &ieeeAddress) const;

signals:
    void countChanged();

protected:
    QList<ZigbeeNode *> m_nodes;

};

Q_DECLARE_METATYPE(ZigbeeNodes*)

#endif // ZIGBEENODES_H
