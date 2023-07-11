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

#include "zigbeeadapter.h"

ZigbeeAdapter::ZigbeeAdapter(QObject *parent) : QObject(parent)
{

}

QString ZigbeeAdapter::name() const
{
    return m_name;
}

void ZigbeeAdapter::setName(const QString &name)
{
    m_name = name;
    emit nameChanged();
}

QString ZigbeeAdapter::description() const
{
    return m_description;
}

void ZigbeeAdapter::setDescription(const QString &description)
{
    m_description = description;
    emit descriptionChanged();
}

QString ZigbeeAdapter::serialPort() const
{
    return m_serialPort;
}

void ZigbeeAdapter::setSerialPort(const QString &serialPort)
{
    m_serialPort = serialPort;
    emit serialPortChanged();
}

QString ZigbeeAdapter::serialNumber() const
{
    return m_serialNumber;
}

void ZigbeeAdapter::setSerialNumber(const QString &serialNumber)
{
    m_serialNumber = serialNumber;
    emit serialNumberChanged();
}

bool ZigbeeAdapter::hardwareRecognized() const
{
    return m_hardwareRecognized;
}

void ZigbeeAdapter::setHardwareRecognized(bool hardwareRecognized)
{
    m_hardwareRecognized = hardwareRecognized;
    emit hardwareRecognizedChanged();
}

QString ZigbeeAdapter::backend() const
{
    return m_backend;
}

void ZigbeeAdapter::setBackend(const QString &backend)
{
    m_backend = backend;
    emit backendChanged();
}

qint32 ZigbeeAdapter::baudRate() const
{
    return m_baudRate;
}

void ZigbeeAdapter::setBaudRate(qint32 baudRate)
{
    m_baudRate = baudRate;
    emit baudRateChanged();
}

bool ZigbeeAdapter::operator==(const ZigbeeAdapter &other) const
{
    return m_serialPort == other.serialPort()
            && m_name == other.name()
            && m_description == other.description()
            && m_hardwareRecognized == other.hardwareRecognized()
            && m_backend == other.backend()
            && m_baudRate == other.baudRate();
}

QDebug operator<<(QDebug dbg, const ZigbeeAdapter &adapter)
{
    dbg.nospace() << "ZigbeeAdapter(" << adapter.name() << " - " << adapter.description();
    dbg.nospace() << ", " << adapter.serialPort();
    if (adapter.hardwareRecognized()) {
        dbg.nospace() << " Hardware recognized: " << adapter.backend();
        dbg.nospace() << ", " << adapter.baudRate();
    }

    dbg.nospace() << ")";
    return dbg.space();
}
