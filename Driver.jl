include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)

customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)


# To do: Check for empty routes

potentials = BestTwoOpt(10,s,Q,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)

SolutionCheck(potentials[1][2],potentials[1][3],unvisitedCustomers,instance)

newVehiclePlan = potentials[1][3]

PlotSolution(newVehiclePlan,160,10,instance)
