// SPDX-License-Identifier: GPL-3.0-or-later

#include "rfidmanager.h"

#include <QJsonDocument>
#include <QMetaEnum>

#include <logging.h>

NYMEA_LOGGING_CATEGORY(dcRfidExperience, "RfidExperience")

RfidManager::RfidManager(QObject *parent)
    : QObject(parent),
      m_tags(new RfidTags(this))
{
}

RfidManager::~RfidManager()
{
    if (m_engine)
        m_engine->jsonRpcClient()->unregisterNotificationHandler(this);
}

Engine *RfidManager::engine() const
{
    return m_engine;
}

void RfidManager::setEngine(Engine *engine)
{
    if (m_engine == engine)
        return;

    if (m_engine)
        m_engine->jsonRpcClient()->unregisterNotificationHandler(this);

    m_engine = engine;
    emit engineChanged();

    if (!m_engine)
        return;

    connect(engine, &Engine::destroyed, this, [engine, this]() {
        if (m_engine == engine)
            m_engine = nullptr;
    });

    m_engine->jsonRpcClient()->registerNotificationHandler(this, "Rfid", "notificationReceived");
    refreshTags();
}

RfidTags *RfidManager::tags() const
{
    return m_tags;
}

int RfidManager::refreshTags(const QString &username)
{
    QVariantMap params;
    if (!username.trimmed().isEmpty())
        params.insert("username", username.trimmed());

    return m_engine->jsonRpcClient()->sendCommand("Rfid.GetTags", params, this, "getTagsResponse");
}

int RfidManager::addTag(const QString &username, const QString &code, const QString &displayName, bool enabled, const QVariantMap &profile)
{
    QVariantMap params;
    params.insert("username", username.trimmed());
    params.insert("code", code);

    if (!displayName.trimmed().isEmpty())
        params.insert("displayName", displayName.trimmed());

    params.insert("enabled", enabled);

    if (!profile.isEmpty())
        params.insert("profile", profile);

    return m_engine->jsonRpcClient()->sendCommand("Rfid.AddTag", params, this, "addTagResponse");
}

int RfidManager::updateTag(const QUuid &inventoryItemId, const QString &displayName, bool enabled, const QVariantMap &profile)
{
    QVariantMap params;
    params.insert("inventoryItemId", inventoryItemId);
    params.insert("displayName", displayName.trimmed());
    params.insert("enabled", enabled);
    params.insert("profile", profile);
    return m_engine->jsonRpcClient()->sendCommand("Rfid.UpdateTag", params, this, "updateTagResponse");
}

int RfidManager::removeTag(const QUuid &inventoryItemId)
{
    return m_engine->jsonRpcClient()->sendCommand("Rfid.RemoveTag", {{"inventoryItemId", inventoryItemId}}, this, "removeTagResponse");
}

void RfidManager::notificationReceived(const QVariantMap &data)
{
    const QString notification = data.value("notification").toString();
    const QVariantMap params = data.value("params").toMap();

    if (notification == "Rfid.TagAdded" || notification == "Rfid.TagChanged") {
        const QVariantMap tagMap = extractTagMap(params);
        if (!tagMap.isEmpty())
            m_tags->upsertTag(tagMap);
    } else if (notification == "Rfid.TagRemoved") {
        const QUuid inventoryItemId = params.value("inventoryItemId").toUuid();
        if (!inventoryItemId.isNull())
            m_tags->removeTag(inventoryItemId);
    } else if (notification == "Rfid.Authorized" || notification == "Rfid.Denied") {
        qCDebug(dcRfidExperience()) << "RFID authorization notification:" << qUtf8Printable(QJsonDocument::fromVariant(params).toJson(QJsonDocument::Compact));
    } else {
        qCDebug(dcRfidExperience()) << "Unhandled notification received" << data;
    }
}

void RfidManager::getTagsResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcRfidExperience()) << "GetTags response:" << commandId << qUtf8Printable(QJsonDocument::fromVariant(params).toJson(QJsonDocument::Compact));
    const RfidError error = parseError(params);
    emit refreshTagsReply(commandId, error);
    if (error == RfidErrorNoError)
        m_tags->setTags(params.value("tags").toList());
}

void RfidManager::addTagResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcRfidExperience()) << "AddTag response:" << commandId << params;
    emit addTagReply(commandId, parseError(params));
}

void RfidManager::updateTagResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcRfidExperience()) << "UpdateTag response:" << commandId << params;
    emit updateTagReply(commandId, parseError(params));
}

void RfidManager::removeTagResponse(int commandId, const QVariantMap &params)
{
    qCDebug(dcRfidExperience()) << "RemoveTag response:" << commandId << params;
    emit removeTagReply(commandId, parseError(params));
}

QVariantMap RfidManager::extractTagMap(const QVariantMap &params) const
{
    if (params.value("tag").canConvert<QVariantMap>())
        return params.value("tag").toMap();

    if (params.value("rfidTag").canConvert<QVariantMap>())
        return params.value("rfidTag").toMap();

    if (params.contains("inventoryItemId"))
        return params;

    return QVariantMap();
}

RfidManager::RfidError RfidManager::parseError(const QVariantMap &params) const
{
    const QString errorString = params.value("rfidError").toString();
    if (errorString.isEmpty())
        return RfidErrorNoError;

    const QMetaEnum metaEnum = QMetaEnum::fromType<RfidError>();
    const int value = metaEnum.keyToValue(errorString.toUtf8().constData());
    if (value < 0)
        return RfidErrorBackendError;

    return static_cast<RfidError>(value);
}
