/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2020, nymea GmbH
* Contact: contact@nymea.io
*
* This file is part of nymea.
* This project including source code and documentation is protected by
* copyright law, and remains the property of nymea GmbH. All rights, including
* reproduction, publication, editing and translation, are reserved. The use of
* this project is subject to the terms of a license agreement to be concluded
* with nymea GmbH in accordance with the terms of use of nymea GmbH, available
* under https://nymea.io/license
*
* GNU General Public License Usage
* Alternatively, this project may be redistributed and/or modified under the
* terms of the GNU General Public License as published by the Free Software
* Foundation, GNU version 3. This project is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along with
* this project. If not, see <https://www.gnu.org/licenses/>.
*
* For any further details and any questions please contact us under
* contact@nymea.io or see our FAQ/Licensing Information on
* https://nymea.io/license/faq
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "applogcontroller.h"

#include <QStandardPaths>
#include <QDebug>
#include <QSettings>
#include <QGuiApplication>
#include <QDir>
#include <QMutexLocker>

#include "logging.h"

QtMessageHandler AppLogController::s_oldLogMessageHandler = nullptr;


AppLogController::LogLevel AppLogController::qtMsgTypeToLogLevel(QtMsgType msgType)
{
    switch (msgType) {
    case QtDebugMsg:
        return LogLevelDebug;
    case QtInfoMsg:
        return LogLevelInfo;
    case QtWarningMsg:
        return LogLevelWarning;
    default:
        return LogLevelCritical;
    }
}

QtMsgType AppLogController::logLevelToQtMsgType(AppLogController::LogLevel logLevel)
{
    switch (logLevel) {
    case LogLevelDebug:
        return QtDebugMsg;
    case LogLevelInfo:
        return QtInfoMsg;
    case LogLevelWarning:
        return QtWarningMsg;
    default:
        return QtCriticalMsg;
    }
}

QObject *AppLogController::appLogControllerProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)
    return instance();
}

AppLogController *AppLogController::instance()
{
    static AppLogController* thiz = nullptr;
    if (!thiz) {
        thiz = new AppLogController();
    }
    return thiz;
}

AppLogController::AppLogController(QObject *parent) : QObject(parent)
{
    // qt.qml.connections warnings are disabled since the replace only exists
    // in Qt 5.12. Remove that once 5.12 is the minimum supported version.
    QLoggingCategory::setFilterRules("*.debug=false\n"
                                     "qt.qml.connections.warning=false\n"
                                     );

    m_loggingCategories = new LoggingCategories(this);

    QSettings settings;
    settings.beginGroup("LoggingLevels");
    foreach (const QString &category, nymeaLoggingCategories()) {
        m_logLevels[category] = static_cast<LogLevel>(settings.value(category, LogLevelWarning).toInt());
    }
    // Unless specified otherwise by the user, Application info messages are enabled by default for basic information
    if (!settings.childKeys().contains("Application")) {
        m_logLevels["Application"] = LogLevelInfo;
    }
    settings.endGroup();

    updateFilters();

    // Finally, install the logMessageHandler
    s_oldLogMessageHandler = qInstallMessageHandler(&logMessageHandler);

    if (enabled()) {
        openLogFile();
    }
}

bool AppLogController::enabled() const
{
    QSettings settings;
    return settings.value("AppLoggingEnabled", false).toBool();
}

void AppLogController::setEnabled(bool enabled)
{
    if (enabled == this->enabled()) {
        return;
    }

    if (enabled) {
        openLogFile();
    } else {
        m_logFile.close();
    }
    QSettings settings;
    settings.setValue("AppLoggingEnabled", enabled);
    emit enabledChanged();
}

LoggingCategories *AppLogController::loggingCategories() const
{
    return m_loggingCategories;
}

AppLogController::LogLevel AppLogController::logLevel(const QString &category) const
{
    return m_logLevels.value(category);
}

void AppLogController::setLogLevel(const QString &category, AppLogController::LogLevel logLevel)
{
    m_logLevels[category] = logLevel;

    QSettings settings;
    settings.beginGroup("LoggingLevels");
    settings.setValue(category, logLevel);
    settings.endGroup();

    emit categoryChanged(category, logLevel);

    updateFilters();
}

QString AppLogController::logPath() const
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/logs/";
}

QString AppLogController::currentLogFile() const
{
    return logPath() + "/" + QGuiApplication::applicationName() + ".log";
}

QStringList AppLogController::logFiles() const
{
    QDir dir(logPath());
    QStringList files;
    foreach (const QString &file, dir.entryList({QGuiApplication::applicationName() + ".log*"})) {
        files.append(logPath() + "/" + file);
    }
    return files;
}

QString AppLogController::exportLogs()
{
    if (m_logFile.isOpen()) {
        m_logFile.flush();
    }
    QFile f(logPath() + "/" + QGuiApplication::applicationName() + "-logs.txt");
    if (!f.open(QFile::WriteOnly)) {
        return QString();
    }
    foreach (const QString &logFile, logFiles()) {
        QFile l(logFile);
        if (!l.open(QFile::ReadOnly)) {
            continue;
        }
        l.seek(0);
        f.write("\n******** App start ********\n");
        f.write(logFile.toUtf8() + "\n");
        f.write(l.readAll());
    }
    f.close();
    return f.fileName();
}

void AppLogController::logMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &message)
{
    s_oldLogMessageHandler(type, context, message);
    QMetaObject::invokeMethod(instance(), "append", Q_ARG(QString, context.category), Q_ARG(QString, message), Q_ARG(AppLogController::LogLevel, qtMsgTypeToLogLevel(type)));
}

void AppLogController::append(const QString &category, const QString &message, LogLevel level)
{
    if (m_logLevels.value(category) < level) {
        return;
    }

    QDateTime timestamp = QDateTime::currentDateTime();

    if (m_logFile.isOpen()) {
        QHash<LogLevel, QString> t = {
            {LogLevelDebug, "D"},
            {LogLevelInfo, "I"},
            {LogLevelWarning, "W"},
            {LogLevelCritical, "C"}
        };
        QString line = QString("%0:%1:%2: %3\n").arg(timestamp.toString("yyyy-MM-dd hh:mm:ss.zzz"), t.value(level), category, message);
        m_logFile.write(line.toUtf8());
        m_logFile.flush();
    }

    emit messageAdded(timestamp, category, message, level);
}

void AppLogController::updateFilters()
{
    QStringList loggingRules = {"*.warn=false", "*.info=false", "*.debug=false"};

    // Load the rules from nymead.conf file and append them to the rules
    foreach (const QString &category, nymeaLoggingCategories()) {
        LogLevel level = m_logLevels.value(category, LogLevelWarning);
        loggingRules << QString("%1.debug=%2").arg(category).arg(level >= LogLevelDebug ? "true" : "false");
        loggingRules << QString("%1.info=%2").arg(category).arg(level >= LogLevelInfo ? "true" : "false");
        loggingRules << QString("%1.warn=%2").arg(category).arg(level >= LogLevelWarning ? "true" : "false");
    }
    loggingRules << "qt.qml.connections.warning=false";

    QLoggingCategory::setFilterRules(loggingRules.join('\n'));
}

void AppLogController::openLogFile()
{
    // Make sure log dir exists
    if (!QDir().mkpath(logPath())) {
        qWarning() << "Cannot create cache location. Logging will not work.";
    }

    // Rotate old log files, keeping the last 5
    for (int i = 4; i > 0; i--) {
        if (QFile::exists(currentLogFile() + "." + QString::number(i))) {
            if (QFile::exists(currentLogFile() + "." + QString::number(i + 1))) {
                QFile::remove(currentLogFile() + "." + QString::number(i + 1));
            }
            QFile::rename(currentLogFile() + "." + QString::number(i), currentLogFile() + "." + QString::number(i + 1));
        }
    }
    if (QFile::exists(currentLogFile())) {
        QFile::rename(currentLogFile(), currentLogFile() + ".1");
    }

    m_logFile.setFileName(currentLogFile());
    if (!m_logFile.open(QFile::ReadWrite | QFile::Truncate)) {
        qWarning() << "Cannot open logfile for writing.";
    } else {
        qDebug() << "App log opened at" << m_logFile.fileName();
    }
}

LogMessages::LogMessages(QObject *parent):
    QAbstractListModel(parent)
{
    QFile f(AppLogController::instance()->currentLogFile());
    if (!f.open(QFile::ReadOnly)) {
        return;
    }
    QHash<QString, AppLogController::LogLevel> map = {
        {"C", AppLogController::LogLevelCritical},
        {"W", AppLogController::LogLevelWarning},
        {"I", AppLogController::LogLevelInfo},
        {"D", AppLogController::LogLevelDebug}
    };
    while (!f.atEnd()) {
        QByteArray line = f.readLine().trimmed();
        QList<QByteArray> parts = line.split(':');
        if (parts.length() < 6) {
            continue;
        }
        LogMessage message;
        QString timestampString = parts.takeFirst();
        timestampString.append(":" + parts.takeFirst());
        timestampString.append(":" + parts.takeFirst());
        message.timestamp = QDateTime::fromString(timestampString, "yyyy-MM-dd hh:mm:ss.zzz");
        message.level = map.value(parts.takeFirst());
        message.category = parts.takeFirst();
        message.message = parts.join(":");
        m_messages.append(message);
    }
    connect(AppLogController::instance(), &AppLogController::messageAdded, this, &LogMessages::append);
}

int LogMessages::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_messages.count();
}

QVariant LogMessages::data(const QModelIndex &index, int role) const
{
    LogMessage message = m_messages.at(index.row());
    switch (role) {
    case RoleTimestamp:
        return message.timestamp;
    case RoleCategory:
        return message.category;
    case RoleMessage:
        return message.message;
    case RoleLevel:
        return message.level;
    case RoleText:
        return message.timestamp.toString("hh:mm:ss") + ": " + message.category + ": " + message.message;
    }
    return QVariant();
}

QHash<int, QByteArray> LogMessages::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleTimestamp, "timestamp");
    roles.insert(RoleCategory, "category");
    roles.insert(RoleMessage, "message");
    roles.insert(RoleLevel, "level");
    roles.insert(RoleText, "text");
    return roles;
}

void LogMessages::append(const QDateTime &timestamp, const QString &category, const QString &message, AppLogController::LogLevel level)
{
    beginInsertRows(QModelIndex(), m_messages.count(), m_messages.count());
    LogMessage msg;
    msg.timestamp = timestamp;
    msg.category = category;
    msg.message = message;
    msg.level = level;
    m_messages.append(msg);
    endInsertRows();

    int maxEntries = 1024;
    if (m_messages.size() > maxEntries) {
        beginRemoveRows(QModelIndex(), 0, 0);
        m_messages.removeFirst();
        endRemoveRows();
    }
}

LoggingCategories::LoggingCategories(AppLogController *parent):
    QAbstractListModel(parent),
    m_controller(parent)
{
    connect(m_controller, &AppLogController::categoryChanged, this, [=](const QString &category) {
        QModelIndex idx = index(nymeaLoggingCategories().indexOf(category));
        emit dataChanged(idx, idx, {RoleLevel});
    });
}

int LoggingCategories::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return nymeaLoggingCategories().count();
}

QVariant LoggingCategories::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case RoleName:
        return nymeaLoggingCategories().at(index.row());
    case RoleLevel:
        return m_controller->logLevel(nymeaLoggingCategories().at(index.row()));
    }
    return QVariant();
}

QHash<int, QByteArray> LoggingCategories::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleName, "name");
    roles.insert(RoleLevel, "logLevel");
    return roles;
}

QVariant LoggingCategories::data(int index, const QString &role)
{
    return data(this->index(index), roleNames().key(role.toUtf8()));
}

