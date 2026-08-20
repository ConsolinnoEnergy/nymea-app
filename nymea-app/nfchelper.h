// SPDX-License-Identifier: GPL-3.0-or-later

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with nymea-app. If not, see <https://www.gnu.org/licenses/>.
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#ifndef NFCHELPER_H
#define NFCHELPER_H

#include <QObject>
#include <QQmlEngine>
#include <QVariantMap>

class QNearFieldManager;
class QNearFieldTarget;

class NfcHelper : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAvailable READ isAvailable NOTIFY isAvailableChanged)
    Q_PROPERTY(bool tagUidScanningAvailable READ tagUidScanningAvailable NOTIFY isAvailableChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)

public:
    static NfcHelper* instance();
    static QObject *nfcHelperProvider(QQmlEngine *engine, QJSEngine *scriptEngine);


    bool isAvailable() const;
    bool tagUidScanningAvailable() const;
    bool scanning() const;

    static QString formatUid(const QByteArray &uid);
    static QString tagCode(const QByteArray &uid);

    Q_INVOKABLE bool startTagUidScan();
    Q_INVOKABLE void stopTagUidScan();

signals:
    void isAvailableChanged();
    void scanningChanged();
    void tagDetected(const QVariantMap &tagInformation);
    void scanFailed(const QString &message);

private:
    explicit NfcHelper(QObject *parent = nullptr);

    void setScanning(bool scanning);
    void targetDetected(QNearFieldTarget *target);
    QVariantMap tagInformation(QNearFieldTarget *target) const;

    QNearFieldManager *m_manager = nullptr;
    bool m_scanning = false;
};

#endif // NFCHELPER_H
