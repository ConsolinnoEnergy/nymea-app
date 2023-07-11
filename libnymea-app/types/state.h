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

#ifndef STATE_H
#define STATE_H

#include <QUuid>
#include <QObject>
#include <QVariant>

class State : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUuid thingId READ thingId CONSTANT)
    Q_PROPERTY(QUuid stateTypeId READ stateTypeId CONSTANT)
    Q_PROPERTY(QVariant value READ value NOTIFY valueChanged)
    Q_PROPERTY(QVariant minValue READ minValue NOTIFY minValueChanged)
    Q_PROPERTY(QVariant maxValue READ maxValue NOTIFY maxValueChanged)
    Q_PROPERTY(QVariantList possibleValues READ possibleValues NOTIFY possibleValuesChanged)

public:
    explicit State(const QUuid &thingId, const QUuid &stateTypeId, const QVariant &value, QObject *parent = nullptr);

    QUuid thingId() const;
    QUuid stateTypeId() const;

    QVariant value() const;
    void setValue(const QVariant &value);

    QVariant minValue() const;
    void setMinValue(const QVariant &minValue);

    QVariant maxValue() const;
    void setMaxValue(const QVariant &maxValue);

    QVariantList possibleValues() const;
    void setPossibleValues(const QVariantList &possibleValues);

private:
    QUuid m_thingId;
    QUuid m_stateTypeId;
    QVariant m_value;
    QVariant m_minValue;
    QVariant m_maxValue;
    QVariantList m_possibleValues;

signals:
    void valueChanged();
    void minValueChanged();
    void maxValueChanged();
    void possibleValuesChanged();
};

#endif // STATE_H
