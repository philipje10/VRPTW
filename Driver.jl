"""This code contains the implementation of the Tabu search metaheuristic. The implementation
is part of the course 'Optimization using metaheuristics (42137)' on Technical University of
Denmark (DTU). This course is offered in the spring of academic year 2019-2020."""

include("Algorithm.jl")

bestVehiclePlan,bestCustomerPlan,bestDistance = VRPTW(3264236,"data/C1_2_2.TXT",60,true,5,7,15,(5,30),1,18,2)
