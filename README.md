## General information:
This code contains the implementation of the Tabu search metaheuristic. The implementation is part of the course 'Optimization using metaheuristics (42137)' on Technical University of Denmark (DTU). This course is offered in the spring of academic year 2019-2020.

## Running the metaheuristic:
Run the Driver.jl file. Call the VRPTW function with the following parameters:

'VRPTW(seed,instance,timeLimit,twoOptStart,d,I,h,k,R_init,R_operator,maxChain)'

seed:           random seed number (default = 12345)

instance:       path to instance file

timeLimit:      time limit in seconds for the metaheuristic to run (default = 480)

twoOptStart:    logical value indicating whether the heuristic starts with the 2-opt* operator or not (default = true)

d:              step size of increasing or decreasing the dynamic Tabu list (default = 5)

I:              number of successive iterations without improving the overall best solution before going to the next operator (default = 7)

h:              number of neighbors explored for every customer at each iteration (default = 15)

k:				minimum and maximum length of the Tabu list (default = (5,30))

R_init:			number of options to randomly select a next customer in the visiting sequence when building the initial solution (default = 1)

R_operator:		number of random moves after a positive trend occurs after a iteration cycle (default = 18)

maxChain: 		maximum number of chained customers to be inserted into another route when applying the or-opt operator (default = 20)

