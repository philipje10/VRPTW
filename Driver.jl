include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)

# PlotSolution(vehiclePlan,160,10,instance)

# start iteration
i = 0
bestSolution = TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)[1]
tabuList = [(1000,1000) for i = 1:10] # initialize tabu list

time_limit = 180
startTime = time_ns()
while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for 10 sec.

    global vehiclePlan,customerPlan,currentTabu,currentEvaluation = BestTwoOpt(15,tabuList,true,s,Q,bestSolution,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    global tabuList = vcat(tabuList[3:end],currentTabu)

    if currentEvaluation < bestSolution
        global bestSolution = currentEvaluation
        global bestVehiclePlan = vehiclePlan
        global bestCustomerPlan = customerPlan
    end
end

# PlotSolution(bestVehiclePlan,160,10,instance)
# TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
# To solve error: Evaluate number of vehicles
