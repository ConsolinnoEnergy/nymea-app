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

#include "ngwmanager.h"

#include <QMetaEnum>

#include <logging.h>

NYMEA_LOGGING_CATEGORY(dcNgwExperience, "NgwExperience")

NgwManager::NgwManager(QObject *parent)
    : QObject{parent}
{

}

NgwManager::~NgwManager()
{
    if (m_engine) {
        m_engine->jsonRpcClient()->unregisterNotificationHandler(this);
    }
}

Engine *NgwManager::engine() const
{
    return m_engine;
}

void NgwManager::setEngine(Engine *engine)
{
    if (m_engine == engine)
        return;

    if (m_engine)
        m_engine->jsonRpcClient()->unregisterNotificationHandler(this);

    m_engine = engine;
    emit engineChanged();

    if (m_engine) {
        connect(engine, &Engine::destroyed, this, [engine, this]{ if (m_engine == engine) m_engine = nullptr; });

        m_engine->jsonRpcClient()->registerNotificationHandler(this, "Ngw", "notificationReceived");
        m_engine->jsonRpcClient()->sendCommand("Ngw.GetLanConfiguration", QVariantMap(), this, "getLanConfigurationResponse");
    }
}

bool NgwManager::loading() const
{
    return m_loading;
}

bool NgwManager::enabled() const
{
    return m_enabled;
}

NgwManager::GatewayServicesAccess NgwManager::gatewayServicesAccess() const
{
    return m_gatewayServicesAccess;
}

bool NgwManager::internetSharing() const
{
    return m_internetSharing;
}

QString NgwManager::lanInterface() const
{
    return m_lanInterface;
}

QString NgwManager::wanInterface() const
{
    return m_wanInterface;
}

QVariantList NgwManager::configuredGatewayPorts() const
{
    return m_configuredGatewayPorts;
}

QString NgwManager::lanCidr() const
{
    return m_lanCidr;
}

QString NgwManager::lanAddress() const
{
    return m_lanAddress;
}

QString NgwManager::dhcpStart() const
{
    return m_dhcpStart;
}

QString NgwManager::dhcpEnd() const
{
    return m_dhcpEnd;
}

int NgwManager::setLanConfiguration(bool enabled, GatewayServicesAccess gatewayServicesAccess, bool internetSharing)
{
    QMetaEnum accessEnum = QMetaEnum::fromType<GatewayServicesAccess>();
    QVariantMap params = {
        {"enabled", enabled},
        {"gatewayServicesAccess", accessEnum.valueToKey(gatewayServicesAccess)},
        {"internetSharing", internetSharing}
    };
    return m_engine->jsonRpcClient()->sendCommand("Ngw.SetLanConfiguration", params, this, "setLanConfigurationResponse");
}

void NgwManager::notificationReceived(const QVariantMap &data)
{
    QString notification = data.value("notification").toString();
    QVariantMap params = data.value("params").toMap();

    if (notification == "Ngw.LanConfigurationChanged") {
        unpackConfiguration(params.value("configuration").toMap());
    } else {
        qCDebug(dcNgwExperience()) << "Unhandled notification received" << data;
    }
}

void NgwManager::getLanConfigurationResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcNgwExperience()) << "Response for GetLanConfiguration request" << commandId << params;

    unpackConfiguration(params);

    if (m_loading) {
        m_loading = false;
        emit loadingChanged();
    }
}

void NgwManager::setLanConfigurationResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcNgwExperience()) << "Response for SetLanConfiguration request" << commandId << params;

    QMetaEnum errorEnum = QMetaEnum::fromType<NgwError>();
    NgwError error = static_cast<NgwError>(errorEnum.keyToValue(params.value("ngwError").toByteArray().data()));

    if (params.contains("configuredGatewayPorts")) {
        m_configuredGatewayPorts = params.value("configuredGatewayPorts").toList();
        emit configurationChanged();
    }

    emit setLanConfigurationReply(commandId, error, params.value("message").toString());
}

void NgwManager::unpackConfiguration(const QVariantMap &configuration)
{
    QMetaEnum accessEnum = QMetaEnum::fromType<GatewayServicesAccess>();

    int accessValue = accessEnum.keyToValue(configuration.value("gatewayServicesAccess").toByteArray().data());
    m_enabled = configuration.value("enabled").toBool();
    m_gatewayServicesAccess = accessValue >= 0 ? static_cast<GatewayServicesAccess>(accessValue) : GatewayServicesAccessDisabled;
    m_internetSharing = configuration.value("internetSharing").toBool();
    m_lanInterface = configuration.value("lanInterface").toString();
    m_wanInterface = configuration.value("wanInterface").toString();
    m_configuredGatewayPorts = configuration.value("configuredGatewayPorts").toList();
    m_lanCidr = configuration.value("lanCidr").toString();
    m_lanAddress = configuration.value("lanAddress").toString();
    m_dhcpStart = configuration.value("dhcpStart").toString();
    m_dhcpEnd = configuration.value("dhcpEnd").toString();

    emit configurationChanged();
}
