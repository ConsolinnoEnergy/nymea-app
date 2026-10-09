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

void JsonRpcParser::reset(int generation)
{
    m_generation = generation;
    m_receiveBuffer.clear();
}

void JsonRpcParser::parse(const QByteArray &data, int generation)
{
    if (generation != m_generation) {
        // Data from a previous connection
        return;
    }

    m_receiveBuffer.append(data);

    while (!m_receiveBuffer.isEmpty()) {
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

        emit messageParsed(jsonDoc.toVariant().toMap(), m_generation);
    }
}
