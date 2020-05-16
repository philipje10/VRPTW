include("Filereader.jl")
include("HelpFunctions.jl")
include("InitialSolution.jl")
include("2Opt.jl")
include("OrOpt.jl")
include("VehicleMinimization.jl")

"""Metaheuristic applied including the initial solution builder, 2-opt* operation,
and or-opt operation. Monitors the current solution, and overall best solution"""
function VRPTW(seed,instance,timeLimit,twoOptStart,d,I,h,k,R_init,R_operator,maxChain)

    println("")
    println("_________________________________________________")
    println("Info")
    println("")
    println("Instance\t\t\t\t\t: ",instance)
    println("Time limit\t\t\t\t\t: ",timeLimit," seconds")
    println("Time minimizing vehicles\t: ",Int32(round(timeLimit*(1/10),digits = 0))," seconds")
    println("Time minimizing distance\t: ",Int32(round(timeLimit*(9/10),digits = 0))," seconds")
    println("_________________________________________________")

    Random.seed!(seed)

    K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
    customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,R_init)
    totalDistance,usedVehicles,totalWaitingTime = TotalEvaluation(vehiclePlan,customerPlan,instance)

    println("")
    println("_________________________________________________")
    println("Initial solution built")
    println("")
    println("Total distance\t\t: ",totalDistance)
    println("Used vehicles\t\t: ",usedVehicles)
    println("Total waiting time\t: ",totalWaitingTime)
    println("_________________________________________________")

    LB = Int32(ceil(sum(customerDemand/Q))) # Minimal number of vehicles based on capacity
    dSum = k[1]
    TwoOpt = twoOptStart
    tabuListOrOpt = [(1000,1000) for i = 1:k[1]] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k[1]*2)] # initialize tabu list
    bestVehiclePlan = deepcopy(vehiclePlan)
    bestCustomerPlan = deepcopy(customerPlan)
    runTimeAnalysis = DataFrame(time = Float32[],value = Float32[])

    println("")
    println("Start minimizing vehicles ...")
    println("")

    numberOfVehicles = UsedVehicles(vehiclePlan)
    startTime = time_ns()
    while round((time_ns()-startTime)/1e9,digits=3) < timeLimit*(1/10) && numberOfVehicles > LB  # run while loop for t sec.
        currentVehiclePlan,currentCustomerPlan = MinimizeVehicles(h,s,Q,C,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
        if currentVehiclePlan != false && currentCustomerPlan != false
            customerPlan = currentCustomerPlan
            vehiclePlan = currentVehiclePlan
        end
        numberOfVehicles = UsedVehicles(vehiclePlan)
    end

    totalDistance,usedVehicles,totalWaitingTime = TotalEvaluation(vehiclePlan,customerPlan,instance)

    println("")
    println("_________________________________________________")
    println("Vehicles minimized")
    println("")
    println("Total distance\t\t: ",totalDistance)
    println("Used vehicles\t\t: ",usedVehicles)
    println("Total waiting time\t: ",totalWaitingTime)
    println("_________________________________________________")

    println("")
    println("Start minimizing distance ...")
    println("")

    startTime = time_ns()
    while round((time_ns()-startTime)/1e9,digits=3) < timeLimit*(9/10)  # run while loop for t sec.
        if TwoOpt
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt,trend,df = RunTwoOpt(h,s,C,Q,I,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers,depotTimes,customerTimes,customerDemand,tabuListTwoOpt)
            TwoOpt = false
        else
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt,trend,df = RunOrOpt(h,I,C,s,maxChain,Q,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,customerTimes,depotTimes,customerDemand,distCustomers,distDepot,tabuListOrOpt)
            TwoOpt = true
        end
        append!(runTimeAnalysis,df)
        if trend > 0
            try # If no random moves are possible, continue with next iteration
                for i = 1:R_operator
                    vehiclePlan,customerPlan = RandomMove([c for c = 1:C],[],h,Q,s,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers,depotTimes,customerTimes)
                end
            catch
                continue
            end
        elseif trend >= -1 && dSum < k[2]
            dSum += d
            tabuListOrOpt = vcat([(1000,1000) for i = 1:d],tabuListOrOpt)
            tabuListTwoOpt = vcat([(1000,1000) for i = 1:d*2],tabuListTwoOpt)
        elseif trend < -1 && dSum > k[1]
            dSum -= d
            tabuListOrOpt = tabuListOrOpt[d+1:end]
            tabuListTwoOpt = tabuListTwoOpt[d*2+1:end]
        end
    end

    runTimeAnalysis.time = CorrectTime.(startTime,runTimeAnalysis.time)
    CSV.write("RunTimeAnalysis.csv", runTimeAnalysis)

    totalDistance,usedVehicles,totalWaitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)

    println("")
    println("Finished!")
    println("")
    println("___________________________________________")
    println("Best found solution")
    println("")
    println("Total distance\t\t: ",totalDistance)
    println("Used vehicles\t\t: ",usedVehicles)
    println("Total waiting time\t: ",totalWaitingTime)
    println("___________________________________________")

    return bestVehiclePlan,bestCustomerPlan,totalDistance
end


"""Function that iterates through all the instances in the /data map (must be inside project
map). The number of seeds is also the number of samples for each instance in the map. Output
file is a csv with evaluation values"""
function RunInstances(seeds,timeLimit)
    data = Any[]
    df = DataFrame(Instance = Any[], Seed = Int32[], Trucks = Int32[], Distance = Float32[], WaitingTime = Float32[])

    for (root, dirs, files) in walkdir("./data")
        for file in files
            name = string((joinpath(root, file)))
            push!(data,name)
        end
    end

    for seed in seeds
        for instance in data
            bestVehiclePlan,bestCustomerPlan,bestDistance = VRPTW(seed,instance,timeLimit,true,5,7,15,(5,30),1,18,2)
            totalDistance,usedVehicles,waitingTime = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,instance)
            instanceName = split(split(instance,"/")[end],".")[1]
            push!(df,[instanceName,seed,usedVehicles,totalDistance,waitingTime])
        end
    end

    CSV.write("Results.csv", df)
end
