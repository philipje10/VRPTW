include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")
include("OrOpt.jl")

instance = "data/C1_2_8.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)

PlotSolution(vehiclePlan,160,10,instance)

PrintSolution(vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes)
k = 15
bestVehiclePlan = vehiclePlan
bestCustomerPlan = customerPlan

time_limit = 600
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for t sec.
    tabuListOrOpt = [(1000,1000) for i = 1:k] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k*2)] # initialize tabu list

    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt = RunTwoOpt(15,15,20,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt)
    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt = RunOrOpt(15,15,20,2,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt)

end
println((time_ns() - startTime)/1e9)

PlotSolution(bestVehiclePlan,160,10,instance)
# # To solve error: Evaluate number of vehicles
TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
PrintSolution(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers,depotTimes,customerTimes)
