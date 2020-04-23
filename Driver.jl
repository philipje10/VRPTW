include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)

PlotSolution(vehiclePlan,160,10,instance)

# start iteration
i = 0
bestSolution = TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)[1]
tabuList = [] # initialize tabu list (empty)
while i < 100
    global vehiclePlan,customerPlan,currentTabu = BestTwoOpt(10,tabuList,true,s,Q,bestSolution,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    if length(tabuList) > 10
        global tabuList = vcat(tabuList[3:end],currentTabu)
    else
        global tabuList = vcat(tabuList,currentTabu)
    end
    if TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)[1] < bestSolution
        global bestSoltion = TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)[1]
    end
    global i += 1
end
#
PlotSolution(vehiclePlan,160,10,instance)

# To solve error: Multiple values in tabu list
# SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)
