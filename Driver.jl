include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")



instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)

# PlotSolution(vehiclePlan,160,10,instance)
# function Driver()

bestSolution = TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)[1]
bestVehiclePlan = vehiclePlan
bestCustomerPlan = customerPlan

# time_limit = 60
# startTime = time_ns()
# while round((time_ns()-startTime)/1e9,digits=3) < time_limit  # run while loop for 10 sec.


testSolution,testVehiclePlan,testCustomerPlan = RunTwoOpt(10,5,5,bestVehiclePlan,bestCustomerPlan)

bestSolution,bestVehiclePlan,bestCustomerPlan = RunOrOpt(10,5,5,3,testVehiclePlan,testCustomerPlan)

end
# end




# PlotSolution(bestVehiclePlan,160,10,instance)
# TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
# To solve error: Evaluate number of vehicles
#                   Delta evaluation
