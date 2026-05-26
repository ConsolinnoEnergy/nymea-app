// SPDX-License-Identifier: LGPL-3.0-or-later

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright (C) 2013 - 2024, nymea GmbH
* Copyright (C) 2024 - 2025, chargebyte austria GmbH
*
* This file is part of libnymea-app.
*
* libnymea-app is free software: you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public License
* as published by the Free Software Foundation, either version 3
* of the License, or (at your option) any later version.
*
* libnymea-app is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License
* along with libnymea-app. If not, see <https://www.gnu.org/licenses/>.
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "tunnelproxytransport.h"

#include <QCoreApplication>
#include <QUrlQuery>

using namespace remoteproxyclient;

#include "logging.h"

// Note: Re-registering the same category as the proxy lib offers, so we can control it in the app
// However, as we can't link the same category twice, let's just create a dummy here with the category string matching the lib
NYMEA_LOGGING_CATEGORY(dcTunnelProxyRemoteConnectionDummy, "TunnelProxyRemoteConnection")

TunnelProxyTransport::TunnelProxyTransport(QObject *parent) :
    NymeaTransportInterface(parent)
{
#ifdef Q_OS_WASM
    m_remoteConnection = new TunnelProxyRemoteConnection(QUuid::createUuid(), qApp->applicationName(), TunnelProxyRemoteConnection::ConnectionTypeWebSocket, this);
#else
    m_remoteConnection = new TunnelProxyRemoteConnection(QUuid::createUuid(), qApp->applicationName(), this);
#endif
    QObject::connect(m_remoteConnection, &TunnelProxyRemoteConnection::stateChanged, this, &TunnelProxyTransport::onRemoteConnectionStateChanged);
    QObject::connect(m_remoteConnection, &TunnelProxyRemoteConnection::dataReady, this, &TunnelProxyTransport::dataReady);
    QObject::connect(m_remoteConnection, &TunnelProxyRemoteConnection::errorOccurred, this, &TunnelProxyTransport::onRemoteConnectionErrorOccurred);
#ifndef Q_OS_WASM
    QObject::connect(m_remoteConnection, &TunnelProxyRemoteConnection::sslErrors, this, [=](const QList<QSslError> &errors){
        qCWarning(dcTunnelProxyRemoteConnectionDummy) << "Remote tunnel proxy server SSL errors occurred:";
        foreach (const QSslError &sslError, errors) {
            qCWarning(dcTunnelProxyRemoteConnectionDummy) << "  --> " << sslError.errorString();
        }
    });
#endif

}

bool TunnelProxyTransport::connect(const QUrl &url)
{
    m_url = url;

    QUrl serverUrl;
#ifdef Q_OS_WASM
    serverUrl.setScheme(url.scheme() == "tunnels" ? "wss" : "ws");
#else
    serverUrl.setScheme(url.scheme() == "tunnels" ? "ssl" : "tcp");
#endif
    serverUrl.setHost(url.host());
    serverUrl.setPort(url.port());
    QUuid serverUuid(QUrlQuery(url).queryItemValue("uuid"));

    if (!serverUrl.isValid() || serverUrl.host().isEmpty()) {
        qCWarning(dcTunnelProxyRemoteConnectionDummy) << "Invalid tunnel proxy URL" << url;
        return false;
    }

    return m_remoteConnection->connectServer(serverUrl, serverUuid);
}

QUrl TunnelProxyTransport::url() const
{
    return m_url;
}

NymeaTransportInterface::ConnectionState TunnelProxyTransport::connectionState() const
{
    NymeaTransportInterface::ConnectionState state = NymeaTransportInterface::ConnectionStateDisconnected;
    switch (m_remoteConnection->state()) {
    case TunnelProxyRemoteConnection::StateRemoteConnected:
        state = NymeaTransportInterface::ConnectionStateConnected;
        break;
    case TunnelProxyRemoteConnection::StateConnecting:
    case TunnelProxyRemoteConnection::StateHostLookup:
    case TunnelProxyRemoteConnection::StateConnected:
    case TunnelProxyRemoteConnection::StateInitializing:
    case TunnelProxyRemoteConnection::StateRegister:
        state = NymeaTransportInterface::ConnectionStateConnecting;
        break;
    case TunnelProxyRemoteConnection::StateDiconnecting:
    case TunnelProxyRemoteConnection::StateDisconnected:
        state = NymeaTransportInterface::ConnectionStateDisconnected;
        break;
    }
    return state;
}

void TunnelProxyTransport::disconnect()
{
    m_remoteConnection->disconnectServer();
}

void TunnelProxyTransport::sendData(const QByteArray &data)
{
    m_remoteConnection->sendData(data);
}

#ifndef Q_OS_WASM
void TunnelProxyTransport::ignoreSslErrors(const QList<QSslError> &errors)
{
    // FIXME: once the tunnel connection implements SSL connection trought the tunnel proxy, we need to implement this
    Q_UNUSED(errors)
}
#endif

bool TunnelProxyTransport::isEncrypted() const
{
    return false;
}

#ifndef Q_OS_WASM
QSslCertificate TunnelProxyTransport::serverCertificate() const
{
    // FIXME: once the tunnel connection implements SSL connection trought the tunnel proxy, we need to implement this
    return QSslCertificate();
}
#endif

void TunnelProxyTransport::onRemoteConnectionStateChanged(remoteproxyclient::TunnelProxyRemoteConnection::State state)
{
    switch (state) {
    case remoteproxyclient::TunnelProxyRemoteConnection::StateRemoteConnected:
        emit connected();
        break;
    case remoteproxyclient::TunnelProxyRemoteConnection::StateDisconnected:
        emit disconnected();
        break;
    default:
        break;
    }
}

void TunnelProxyTransport::onRemoteConnectionErrorOccurred(QAbstractSocket::SocketError error)
{
    qCWarning(dcTunnelProxyRemoteConnectionDummy) << "Tunnel proxy socket error occurred" << error;
}

NymeaTransportInterface *TunnelProxyTransportFactory::createTransport(QObject *parent) const
{
    return new TunnelProxyTransport(parent);
}

QStringList TunnelProxyTransportFactory::supportedSchemes() const
{
    return { "tunnel", "tunnels" };
}
