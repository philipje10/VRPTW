include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")

instance = "data/C1_2_1.TXT"

customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,5,5)
SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)

PlotSolution(vehiclePlan,160,10,instance)
