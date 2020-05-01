include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")
include("OrOpt.jl")
include("VehicleMinimization.jl")

instance = "data/C1_2_2.TXT"


K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,2,rand(1:10^10))


PrintSolution(vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes)

time_limit = 300
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for t sec.

    currentVehiclePlan,currentCustomerPlan = MinimizeVehicles(15,s,Q,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    if currentVehiclePlan != false && currentCustomerPlan != false
        global customerPlan = currentCustomerPlan
        global vehiclePlan = currentVehiclePlan
    end
end






k = 15
bestVehiclePlan = vehiclePlan
bestCustomerPlan = customerPlan

time_limit = 300
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for t sec.
    tabuListOrOpt = [(1000,1000) for i = 1:k] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k*2)] # initialize tabu list

    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt = RunTwoOpt(15,10,15,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt)
    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt = RunOrOpt(15,10,15,1,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt)

end

PlotSolution(bestVehiclePlan,160,10,instance)
