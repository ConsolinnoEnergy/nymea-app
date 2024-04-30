


#ifndef MOVINGAVERAGE_H
#define MOVINGAVERAGE_H

#include <queue>

class MovingAverage {
private:
    std::queue<int> window;
    int windowSize;
    double sum;
    
public:
    MovingAverage(int size);

    void next(double val);

    double getAverage(); 
};



#endif // MOVINGAVERAGE_H
