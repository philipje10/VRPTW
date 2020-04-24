include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

neighbours = FindNeighbours(j,distCustomers,customerPlan,h)
