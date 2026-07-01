// SPDX-License-Identifier: GPL-3.0-or-later

#ifndef RFIDMANAGER_H
#define RFIDMANAGER_H

#include <QObject>
#include <QUuid>

#include <engine.h>

#include "rfidtags.h"

class RfidManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Engine *engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(RfidTags *tags READ tags CONSTANT)

public:
    enum RfidError {
        RfidErrorNoError = 0,
        RfidErrorBackendError,
        RfidErrorInvalidParameter,
        RfidErrorUserNotFound,
        RfidErrorTagNotFound,
        RfidErrorDuplicateTag,
        RfidErrorInvalidProfile
    };
    Q_ENUM(RfidError)

    explicit RfidManager(QObject *parent = nullptr);
    ~RfidManager();

    Engine *engine() const;
    void setEngine(Engine *engine);

    RfidTags *tags() const;

    Q_INVOKABLE int refreshTags(const QString &username = QString());
    Q_INVOKABLE int addTag(const QString &username, const QString &code, const QString &displayName, bool enabled, const QVariantMap &profile);
    Q_INVOKABLE int updateTag(const QUuid &inventoryItemId, const QString &displayName, bool enabled, const QVariantMap &profile);
    Q_INVOKABLE int removeTag(const QUuid &inventoryItemId);

signals:
    void engineChanged();

    void refreshTagsReply(int commandId, RfidManager::RfidError error);
    void addTagReply(int commandId, RfidManager::RfidError error);
    void updateTagReply(int commandId, RfidManager::RfidError error);
    void removeTagReply(int commandId, RfidManager::RfidError error);

private slots:
    void notificationReceived(const QVariantMap &data);
    void getTagsResponse(int commandId, const QVariantMap &params);
    void addTagResponse(int commandId, const QVariantMap &params);
    void updateTagResponse(int commandId, const QVariantMap &params);
    void removeTagResponse(int commandId, const QVariantMap &params);

private:
    QVariantMap extractTagMap(const QVariantMap &params) const;
    RfidError parseError(const QVariantMap &params) const;

    Engine *m_engine = nullptr;
    RfidTags *m_tags = nullptr;
};

#endif // RFIDMANAGER_H
