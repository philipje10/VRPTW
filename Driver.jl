"""This code contains the implementation of the Tabu search metaheuristic. The implementation
is part of the course 'Optimization using metaheuristics (42137)' on Technical University of
Denmark (DTU). This course is offered in the spring of academic year 2019-2020."""

include("Algorithm.jl")

instance = "data/C1_2_9.TXT"
bestVehiclePlan,bestCustomerPlan,bestDistance = VRPTW(85673,instance,480,true,5,7,15,(5,30),1,18,2)
PrintSolution(bestVehiclePlan,bestCustomerPlan,instance)
