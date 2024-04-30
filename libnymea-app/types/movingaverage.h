


#ifndef MOVINGAVERAGE_H
#define MOVINGAVERAGE_H

#include <iostream>
#include <queue>

class MovingAverage {
private:
    std::queue<int> window;
    int windowSize;
    double sum;
    
public:
    MovingAverage(int size);

    double next(double val);

    double getAverage(); 
};



#endif // MOVINGAVERAGE_H
