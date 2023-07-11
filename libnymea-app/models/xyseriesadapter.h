#ifndef XYSERIESADAPTER_H
#define XYSERIESADAPTER_H

#include "logsmodel.h"

#include <QObject>
#include <QXYSeries>

class XYSeriesAdapter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(LogsModel* logsModel READ logsModel WRITE setLogsModel NOTIFY logsModelChanged)
    Q_PROPERTY(QtCharts::QXYSeries* xySeries READ xySeries WRITE setXySeries NOTIFY xySeriesChanged)
    Q_PROPERTY(QtCharts::QXYSeries* baseSeries READ baseSeries WRITE setBaseSeries NOTIFY baseSeriesChanged)

    Q_PROPERTY(SampleRate sampleRate READ sampleRate WRITE setSampleRate NOTIFY sampleRateChanged)
    Q_PROPERTY(bool smooth READ smooth WRITE setSmooth NOTIFY smoothChanged)
    Q_PROPERTY(bool inverted READ inverted WRITE setInverted NOTIFY invertedChanged)

    Q_PROPERTY(qreal maxValue READ maxValue NOTIFY maxValueChanged)
    Q_PROPERTY(qreal minValue READ minValue NOTIFY minValueChanged)

public:
    enum SampleRate {
        SampleRateSecond = 1,
        SampleRateMinute = 60,
        SampleRate10Minutes = 60 * 10,
        SampleRateHour =  60 * 60,
        SampleRateDays = 24 * 60 * 60
    };
    Q_ENUM(SampleRate)

    explicit XYSeriesAdapter(QObject *parent = nullptr);

    LogsModel* logsModel() const;
    void setLogsModel(LogsModel *logsModel);

    QtCharts::QXYSeries* xySeries() const;
    void setXySeries(QtCharts::QXYSeries *series);

    QtCharts::QXYSeries* baseSeries() const;
    void setBaseSeries(QtCharts::QXYSeries *series);

    SampleRate sampleRate() const;
    void setSampleRate(SampleRate sampleRate);

    bool smooth() const;
    void setSmooth(bool smooth);

    bool inverted() const;
    void setInverted(bool inverted);

    qreal maxValue() const;
    qreal minValue() const;

    Q_INVOKABLE void ensureSamples(const QDateTime &from, const QDateTime &to);

signals:
    void xySeriesChanged();
    void logsModelChanged();
    void baseSeriesChanged();
    void sampleRateChanged();
    void smoothChanged();
    void invertedChanged();
    void maxValueChanged();
    void minValueChanged();

private slots:
    void logEntryAdded(LogEntry *entry);

private:
    qreal calculateSampleValue(int index);

private:
    class Sample {
    public:
        QDateTime timestamp; // The timestamp where this sample *ends*
        QVector<LogEntry*> entries; // all log entries in this sample, that is, from timestamp - smaple size to timestamp
        LogEntry *startingPoint = nullptr; // the starting point for the sample. Normally the last entry of the previous sample
    };
    LogsModel* m_model = nullptr;
    QtCharts::QXYSeries* m_series = nullptr;
    QtCharts::QXYSeries* m_baseSeries = nullptr;
    SampleRate m_sampleRate = SampleRateSecond;
    bool m_smooth = true;
    bool m_inverted = false;

    QVector<Sample*> m_samples;
    QDateTime m_newestSample;
    QDateTime m_oldestSample;

    qreal m_maxValue = 0;
    qreal m_minValue = 0;
};

#endif // XYSERIESADAPTER_H
