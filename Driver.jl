include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")
include("OrOpt.jl")

instance = "data/R2_2_5.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)

# PlotSolution(vehiclePlan,160,10,instance)

PrintSolution(vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes)

bestVehiclePlan = vehiclePlan
bestCustomerPlan = customerPlan

time_limit = 10
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for 10 sec.

    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan = RunTwoOpt(15,5,15,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan)
    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan = RunOrOpt(15,5,15,1,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan)

end

PlotSolution(bestVehiclePlan,160,10,instance)
TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
# # To solve error: Evaluate number of vehicles
# #                   Delta evaluation
