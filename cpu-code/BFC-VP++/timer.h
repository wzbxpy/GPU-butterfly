#include<bits/stdc++.h>
#ifndef _t_
#define _t_
class timer{
    public:
        double begin;
        double end;
        timer(){
            begin = 0;
            end = 0;
        }
        void reset(){
            begin = 0;
            end = 0;
        }
        void start(){
            begin = clock();
        }
        void fin(){
            end = clock();
        }
        double getTime(){
            return (end - begin) / CLOCKS_PER_SEC;
        }
};
#endif