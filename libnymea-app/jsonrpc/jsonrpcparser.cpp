#include "jsonrpcparser.h"

#include <QJsonDocument>
#include <QJsonParseError>

#include "logging.h"

// Defined in jsonrpcclient.cpp
const QLoggingCategory &dcJsonRpc();

JsonRpcParser::JsonRpcParser(QObject *parent):
    QObject(parent)
{
}

void JsonRpcParser::setLatestGeneration(int generation)
{
    m_latestGeneration = generation;
}

void JsonRpcParser::reset(int generation)
{
    m_generation = generation;
    m_receiveBuffer.clear();
}

void JsonRpcParser::parse(const QByteArray &data, int generation)
{
    if (generation != m_generation || generation != m_latestGeneration) {
        // Data from a previous connection
        return;
    }

    m_receiveBuffer.append(data);

    // Parsing is deferred until all chunks that are already queued have been appended.
    // Otherwise every chunk of a large message would trigger a new parse of the whole buffer.
    if (!m_processScheduled) {
        m_processScheduled = true;
        QMetaObject::invokeMethod(this, &JsonRpcParser::process, Qt::QueuedConnection);
    }
}

void JsonRpcParser::process()
{
    m_processScheduled = false;
    const int generation = m_generation;

    while (!m_receiveBuffer.isEmpty()) {
        if (generation != m_latestGeneration) {
            m_receiveBuffer.clear();
            return;
        }
        int splitIndex = static_cast<int>(m_receiveBuffer.indexOf("}\n{")) + 1;
        if (splitIndex <= 0) {
            splitIndex = m_receiveBuffer.length();
        }
        QJsonParseError error;
        QJsonDocument jsonDoc = QJsonDocument::fromJson(m_receiveBuffer.left(splitIndex), &error);
        qCDebug(dcJsonRpc()) << "Received JSON doc. Error:" << error.errorString();
        qCDebug(dcJsonRpc()).noquote() << QString::fromUtf8(jsonDoc.toJson());
        if (error.error != QJsonParseError::NoError) {
            // Incomplete message, wait for more data
            return;
        }
        m_receiveBuffer = m_receiveBuffer.right(m_receiveBuffer.length() - splitIndex - 1);

        emit messageParsed(jsonDoc.toVariant().toMap(), generation);
    }
}
