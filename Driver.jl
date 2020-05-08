include("Algorithm.jl")

data = Any[]
seeds = [934759834,129754360]
df = DataFrame(Instance = Any[], Seed = Int32[], Trucks = Int32[], Distance = Float32[], WaitingTime = Float32[])

for (root, dirs, files) in walkdir("./data")
    for file in files
        name = string((joinpath(root, file)))
        push!(data,name)
        # push!(instances,string((joinpath(root, file)))) # path to files
    end
end

for seed in seeds
    for instance in data
        bestVehiclePlan,bestCustomerPlan,bestDistance = VRPTW(seed,instance,20,true,5,7,15,(5,30),1,18,2)
        totalDistance,usedVehicles,waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)
        instanceName = split(split(instance,"/")[end],".")[1]
        push!(df,[instanceName,seed,usedVehicles,totalDistance,waitingTime])
    end
end

CSV.write("Results.csv", df)

# PlotSolution(bestVehiclePlan,instance)
# PrintSolution(bestVehiclePlan,bestCustomerPlan,instance)
# totalDistance,usedVehicles,waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)
