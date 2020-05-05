include("Filereader.jl")
include("HelpFunctions.jl")
include("InitialSolution.jl")
include("2Opt.jl")
include("OrOpt.jl")
include("VehicleMinimization.jl")

function VRPTW(seed,instance,timeLimit,twoOptStart,tenure,I,h,k,initialRandomness,operatorRandomness,maxChain)
    Random.seed!(seed)

    K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
    customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,initialRandomness)

    println(TotalEvaluation(vehiclePlan,customerPlan,instance))

    LB = Int32(ceil(sum(customerDemand/Q))) # Minimal number of vehicles based on capacity
    dSum = k[1]
    TwoOpt = twoOptStart
    tabuListOrOpt = [(1000,1000) for i = 1:k[1]] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k[1]*2)] # initialize tabu list
    bestVehiclePlan = deepcopy(vehiclePlan)
    bestCustomerPlan = deepcopy(customerPlan)

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

    println(TotalEvaluation(vehiclePlan,customerPlan,instance))

    startTime = time_ns()
    while round((time_ns()-startTime)/1e9,digits=3) < timeLimit*(9/10)  # run while loop for t sec.
        if TwoOpt
            # println("tabuTwoOpt = ",tabuListTwoOpt)
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt,trend = RunTwoOpt(h,s,C,Q,I,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers,depotTimes,customerTimes,customerDemand,tabuListTwoOpt)
            TwoOpt = false
        else
            # println("tabuOrOpt = ",tabuListOrOpt)
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt,trend = RunOrOpt(h,I,C,s,maxChain,Q,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,customerTimes,depotTimes,customerDemand,distCustomers,distDepot,tabuListOrOpt)
            TwoOpt = true
        end
        if trend > 0
            for i = 1:operatorRandomness
                vehiclePlan,customerPlan = RandomMove([c for c = 1:C],[],h,Q,s,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers,depotTimes,customerTimes)
            end
        elseif trend >= -1 && dSum < k[2]
            d = tenure
            dSum += d
            tabuListOrOpt = vcat([(1000,1000) for i = 1:d],tabuListOrOpt)
            tabuListTwoOpt = vcat([(1000,1000) for i = 1:d*2],tabuListTwoOpt)
        elseif trend < -1 && dSum > k[1]
            d = tenure
            dSum -= d
            tabuListOrOpt = tabuListOrOpt[d+1:end]
            tabuListTwoOpt = tabuListTwoOpt[d*2+1:end]
        end
        # println("d = ",dSum)
    end
    bestDistance = TotalDistance(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
    return bestDistance
end
