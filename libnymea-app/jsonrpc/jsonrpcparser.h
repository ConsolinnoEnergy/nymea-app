#ifndef JSONRPCPARSER_H
#define JSONRPCPARSER_H

#include <QObject>
#include <QByteArray>
#include <QVariantMap>

// Splits the incoming byte stream into JSON messages and parses them.
// Intended to live in a dedicated thread so that parsing large replies doesn't block the main thread.
// Messages are emitted in the order they have been received.
class JsonRpcParser : public QObject
{
    Q_OBJECT
public:
    explicit JsonRpcParser(QObject *parent = nullptr);

public slots:
    void parse(const QByteArray &data, int generation);
    void reset(int generation);

signals:
    void messageParsed(const QVariantMap &message, int generation);

private:
    QByteArray m_receiveBuffer;
    int m_generation = 0;
};

#endif // JSONRPCPARSER_H
