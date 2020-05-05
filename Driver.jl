include("Algorithm.jl")

instance = "data/C2_2_4.TXT"


bestVehiclePlan,bestCustomerPlan = VRPTW(1234,instance,300,false,4,15,15,(5,30),1,10,2)

PlotSolution(bestVehiclePlan,instance)
PrintSolution(vehiclePlan,customerPlan,instance)
totalDistance,usedVehicles,waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)
