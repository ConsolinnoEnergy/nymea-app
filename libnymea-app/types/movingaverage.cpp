#include "movingaverage.h"

MovingAverage::MovingAverage(int size): 
windowSize(size), sum(0) 
{
    // insert a init value, so we do not get a 'nan' with the first call of getAverage()
    window.push(0);
}

double MovingAverage::next(double val) 
{
    if (window.size() == windowSize) {
        sum -= window.front();
        window.pop();
    }
    sum += val;
    window.push(val);
    return sum / window.size();
}

double MovingAverage::getAverage() 
{
    return sum / window.size();
}
