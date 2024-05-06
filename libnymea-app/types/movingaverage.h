#ifndef MOVINGAVERAGE_H
#define MOVINGAVERAGE_H

#include <QUuid>
#include <QObject>
#include <QVariant>
#include <queue>

class MovingAverage : public QObject 
{
    Q_OBJECT
    Q_PROPERTY(double value READ value NOTIFY valueChanged)
    Q_PROPERTY(int windowSize READ windowSize WRITE setWindowSize NOTIFY windowSizeChanged)


public:
    explicit MovingAverage(QObject *parent = nullptr);

    double value() const; 

    int windowSize() const;
    void setWindowSize(int size);

    Q_INVOKABLE void next(double val);
    
signals:
    void windowSizeChanged();
    void valueChanged();

private:
    // std::queue<int> window;
    // int windowSize;

    std::queue<int> m_window;
    int m_windowSize=2;
    double m_sum=0;
    double m_value=0;
};



#endif // MOVINGAVERAGE_H
