include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")
include("OrOpt.jl")
include("VehicleMinimization.jl")

instance = "data/R1_2_6.TXT"


K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,2,rand(1:10^10))


PrintSolution(vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes)

time_limit = 300
startTime = time_ns()
LB = Int32(ceil(sum(customerDemand/Q))) # Minimal number of vehicles based on capacity

numberOfVehicles = UsedVehicles(vehiclePlan)
while round((time_ns()-startTime)/1e9,digits=3) < time_limit && numberOfVehicles > LB  # run while loop for t sec.
    currentVehiclePlan,currentCustomerPlan = MinimizeVehicles(15,s,Q,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    if currentVehiclePlan != false && currentCustomerPlan != false
        global customerPlan = currentCustomerPlan
        global vehiclePlan = currentVehiclePlan
    end
    global numberOfVehicles = UsedVehicles(vehiclePlan)
end



k = 7
bestVehiclePlan = vehiclePlan
bestCustomerPlan = customerPlan
bestTotalDistance, vehicles, waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)

time_limit = 600
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for t sec.
    tabuListOrOpt = [(1000,1000) for i = 1:k] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k*2)] # initialize tabu list

    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt = RunTwoOpt(15,k,15,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt)
    totalDistance, vehicles, waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
    if totalDistance == bestTotalDistance
        global k = min(k+2,20)
    elseif totalDistance < bestTotalDistance
        global bestTotalDistance = totalDistance
        global k = max(k-2,7)
    end
    println("k = ",k)

    global vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt = RunOrOpt(15,k,15,2,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt)
    totalDistance, vehicles, waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
    if totalDistance == bestTotalDistance
        global k = min(k+2,20)
    elseif totalDistance < bestTotalDistance
        global bestTotalDistance = totalDistance
        global k = max(k-2,7)
    end
    println("k = ",k)

end

PlotSolution(bestVehiclePlan,160,10,instance)
