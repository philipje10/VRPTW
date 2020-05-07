include("Algorithm.jl")

instance = "data/C2_2_4.TXT"


bestVehiclePlan,bestCustomerPlan,bestDistance = VRPTW(5134,instance,600,true,5,7,15,(5,30),1,18,2)

PlotSolution(bestVehiclePlan,instance)
PrintSolution(vehiclePlan,customerPlan,instance)
totalDistance,usedVehicles,waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)
