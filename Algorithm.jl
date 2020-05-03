include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")
include("OrOpt.jl")
include("VehicleMinimization.jl")

function VRPTW(instance,timeLimit,tenure,I,h,k)

    K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
    customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,2,rand(1:10^10))

    LB = Int32(ceil(sum(customerDemand/Q))) # Minimal number of vehicles based on capacity
    dSum = k
    TwoOpt = true
    tabuListOrOpt = [(1000,1000) for i = 1:k] # initialize tabu list
    tabuListTwoOpt = [(1000,1000) for i = 1:(k*2)] # initialize tabu list
    bestVehiclePlan = vehiclePlan
    bestCustomerPlan = customerPlan

    numberOfVehicles = UsedVehicles(vehiclePlan)
    startTime = time_ns()
    while round((time_ns()-startTime)/1e9,digits=3) < timeLimit*(1/10) && numberOfVehicles > LB  # run while loop for t sec.
        currentVehiclePlan,currentCustomerPlan = MinimizeVehicles(h,s,Q,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
        if currentVehiclePlan != false && currentCustomerPlan != false
            customerPlan = currentCustomerPlan
            vehiclePlan = currentVehiclePlan
        end
        numberOfVehicles = UsedVehicles(vehiclePlan)
    end

    # bestTotalDistance, vehicles, waitingTime = TotalEvaluation(customerPlan,vehiclePlan,distDepot,distCustomers)

    startTime = time_ns()
    while round((time_ns()-startTime)/1e9,digits=3) < timeLimit*(9/10)  # run while loop for t sec.
        if TwoOpt
            println("tabuTwoOpt = ",tabuListTwoOpt)
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt,trend = RunTwoOpt(h,I,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListTwoOpt)
            TwoOpt = false
        else
            println("tabuOrOpt = ",tabuListOrOpt)
            vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt,trend = RunOrOpt(h,I,2,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuListOrOpt)
            TwoOpt = true
        end
        if trend >= -1 && dSum < 30
            d = 4
            dSum += d
            tabuListOrOpt = vcat([(1000,1000) for i = 1:d],tabuListOrOpt)
            tabuListTwoOpt = vcat([(1000,1000) for i = 1:d*2],tabuListTwoOpt)
        elseif trend < -1 && dSum > 5
            d = 4
            dSum -= d
            tabuListOrOpt = tabuListOrOpt[d+1:end]
            tabuListTwoOpt = tabuListTwoOpt[d*2+1:end]
        end
        println("d = ",dSum)
    end
    return bestVehiclePlan,bestCustomerPlan
end

# PlotSolution(bestVehiclePlan,instance)
# PrintSolution(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers,depotTimes,customerTimes)
# println(TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers))
