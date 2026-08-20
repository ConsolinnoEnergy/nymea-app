// SPDX-License-Identifier: GPL-3.0-or-later

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with nymea-app. If not, see <https://www.gnu.org/licenses/>.
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifndef NGWMANAGER_H
#define NGWMANAGER_H

#include <QObject>
#include <QVariantList>

#include "engine.h"

class NgwManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Engine* engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)

    Q_PROPERTY(bool enabled READ enabled NOTIFY configurationChanged)
    Q_PROPERTY(GatewayServicesAccess gatewayServicesAccess READ gatewayServicesAccess NOTIFY configurationChanged)
    Q_PROPERTY(bool internetSharing READ internetSharing NOTIFY configurationChanged)
    Q_PROPERTY(QString lanInterface READ lanInterface NOTIFY configurationChanged)
    Q_PROPERTY(QString wanInterface READ wanInterface NOTIFY configurationChanged)
    Q_PROPERTY(QVariantList configuredGatewayPorts READ configuredGatewayPorts NOTIFY configurationChanged)
    Q_PROPERTY(QString lanCidr READ lanCidr NOTIFY configurationChanged)
    Q_PROPERTY(QString lanAddress READ lanAddress NOTIFY configurationChanged)
    Q_PROPERTY(QString dhcpStart READ dhcpStart NOTIFY configurationChanged)
    Q_PROPERTY(QString dhcpEnd READ dhcpEnd NOTIFY configurationChanged)

public:
    enum GatewayServicesAccess {
        GatewayServicesAccessDisabled,
        GatewayServicesAccessConfiguredPorts,
        GatewayServicesAccessAllPorts
    };
    Q_ENUM(GatewayServicesAccess)

    enum NgwError {
        NgwErrorNoError
        // Any other server-sent key compares unequal to NgwErrorNoError.
    };
    Q_ENUM(NgwError)

    explicit NgwManager(QObject *parent = nullptr);
    ~NgwManager();

    Engine* engine() const;
    void setEngine(Engine *engine);

    bool loading() const;

    bool enabled() const;
    GatewayServicesAccess gatewayServicesAccess() const;
    bool internetSharing() const;
    QString lanInterface() const;
    QString wanInterface() const;
    QVariantList configuredGatewayPorts() const;
    QString lanCidr() const;
    QString lanAddress() const;
    QString dhcpStart() const;
    QString dhcpEnd() const;

    Q_INVOKABLE int setLanConfiguration(bool enabled, GatewayServicesAccess gatewayServicesAccess, bool internetSharing);

signals:
    void engineChanged();
    void loadingChanged();
    void configurationChanged();
    void setLanConfigurationReply(int commandId, NgwManager::NgwError error, const QString &message);

private slots:
    void notificationReceived(const QVariantMap &data);
    void getLanConfigurationResponse(int commandId, const QVariantMap &params);
    void setLanConfigurationResponse(int commandId, const QVariantMap &params);

private:
    void unpackConfiguration(const QVariantMap &configuration);

private:
    Engine *m_engine = nullptr;
    bool m_loading = true;

    bool m_enabled = false;
    GatewayServicesAccess m_gatewayServicesAccess = GatewayServicesAccessDisabled;
    bool m_internetSharing = false;
    QString m_lanInterface;
    QString m_wanInterface;
    QVariantList m_configuredGatewayPorts;
    QString m_lanCidr;
    QString m_lanAddress;
    QString m_dhcpStart;
    QString m_dhcpEnd;
};

#endif // NGWMANAGER_H
