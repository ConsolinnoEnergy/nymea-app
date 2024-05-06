#include "movingaverage.h"


MovingAverage::MovingAverage(QObject *parent): QObject(parent)
{

}


double MovingAverage::value() const
{
    return m_value;
}

int MovingAverage::windowSize() const
{
    return m_windowSize;
}

void MovingAverage::setWindowSize(int size)
{
    m_windowSize = size;
}

void MovingAverage::next(double val) 
{
    if (m_window.size() == m_windowSize) {
        m_sum -= m_window.front();
        m_window.pop();
    }
    m_sum += val;
    m_window.push(val);

    if(m_window.size() != 0) {
        m_value = m_sum / m_window.size();
    }
}