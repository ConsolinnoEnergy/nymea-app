// SPDX-License-Identifier: GPL-3.0-or-later

#include "nfchelper.h"

#include <QTest>

class NfcHelperTest : public QObject
{
    Q_OBJECT

private slots:
    void formatsUidForDisplay_data();
    void formatsUidForDisplay();
    void formatsUidForBackend_data();
    void formatsUidForBackend();
};

void NfcHelperTest::formatsUidForDisplay_data()
{
    QTest::addColumn<QByteArray>("uid");
    QTest::addColumn<QString>("formattedUid");

    QTest::newRow("empty") << QByteArray() << QString();
    QTest::newRow("leading-zero")
            << QByteArray::fromHex("04a1be0b")
            << QStringLiteral("04:A1:BE:0B");
    QTest::newRow("seven-byte")
            << QByteArray::fromHex("047f00112233aa")
            << QStringLiteral("04:7F:00:11:22:33:AA");
}

void NfcHelperTest::formatsUidForDisplay()
{
    QFETCH(QByteArray, uid);
    QFETCH(QString, formattedUid);

    QCOMPARE(NfcHelper::formatUid(uid), formattedUid);
}

void NfcHelperTest::formatsUidForBackend_data()
{
    QTest::addColumn<QByteArray>("uid");
    QTest::addColumn<QString>("tagCode");

    QTest::newRow("empty") << QByteArray() << QString();
    QTest::newRow("lowercase-no-separators")
            << QByteArray::fromHex("04a1be0b")
            << QStringLiteral("04a1be0b");
    QTest::newRow("leading-zero")
            << QByteArray::fromHex("00abcdef")
            << QStringLiteral("00abcdef");
}

void NfcHelperTest::formatsUidForBackend()
{
    QFETCH(QByteArray, uid);
    QFETCH(QString, tagCode);

    QCOMPARE(NfcHelper::tagCode(uid), tagCode);
}

QTEST_MAIN(NfcHelperTest)

#include "tst_nfchelper.moc"
