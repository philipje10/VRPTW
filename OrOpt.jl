include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,5,1)

function OrOptSwitch(i,j,maxLength,Q,customerPlan,vehiclePlan,customerDemand)
    vehicleA = customerPlan[i][1]
    vehicleB = customerPlan[j][1]
    oldRouteA = vehiclePlan[vehicleA][2]
    oldRouteB = vehiclePlan[vehicleB][2]
    cutPointA = Int32(1)
    cutPointB = Int32(1)

    while oldRouteA[cutPointA] != i
        cutPointA += 1
    end

    while oldRouteB[cutPointB] != j
        cutPointB += 1
    end

    tabu = (oldRouteA[cutPointA],oldRouteA[cutPointA-1])

    numberOfCombinations = min(length(oldRouteA) - cutPointA,maxLength)
    newRoutes = Any[]

    for p = 1:numberOfCombinations
        newRouteA = vcat(oldRouteA[1:cutPointA - 1], oldRouteA[cutPointA + p:end])
        newRouteB = vcat(oldRouteB[1:cutPointB], oldRouteA[cutPointA:cutPointA + p - 1] ,oldRouteB[cutPointB+1:end])

        if length(newRouteA) > 2
            capacityA = sum(customerDemand[i] for i in newRouteA[2:end-1])
        else
            newRouteA = [0]
            capacityA = 0
        end
        capacityB = sum(customerDemand[i] for i in newRouteB[2:end-1])
        if capacityA > Q || capacityB > Q
            push!(newRoutes, false)
        else
            push!(newRoutes,[([Float32(capacityA),newRouteA],vehicleA,tabu),([Float32(capacityB),newRouteB],vehicleB,tabu)])
        end
    end
    return newRoutes
end

function BestOrOpt(h,tabuList,distanceEvaluation,maxLength,s,Q,bestSolution,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    currentEvaluation = 10^10
    currentVehiclePlan = vehiclePlan
    currentCustomerPlan = customerPlan
    currentTabu = [(1000,1000)]
    for i = 1:C
        neighbours = FindNeighbours(i,distCustomers,customerPlan,h)
        for j in neighbours
            newRoutes = OrOptSwitch(i,j,maxLength,Q,customerPlan,vehiclePlan,customerDemand)
            for route in newRoutes
                newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                if newCustomerPlan != false
                    newVehiclePlan = deepcopy(vehiclePlan)
                    newVehiclePlan[route[1][2]] = route[1][1]
                    newVehiclePlan[route[2][2]] = route[2][1]
                    if distanceEvaluation == true
                        totalDistance,~,~ = TotalEvaluation(newVehiclePlan,newCustomerPlan,distDepot,distCustomers)
                        if totalDistance < currentEvaluation && (i,j) ∉ tabuList
                            currentEvaluation = totalDistance
                            currentVehiclePlan = newVehiclePlan
                            currentCustomerPlan = newCustomerPlan
                            currentTabu[1] = route[1][3]
                        elseif totalDistance < currentEvaluation && totalDistance < bestSolution # aspiration level (ignore Tabu list if better than overal best)
                            currentEvaluation = totalDistance
                            currentVehiclePlan = newVehiclePlan
                            currentCustomerPlan = newCustomerPlan
                            currentTabu[1] = route[1][3]
                        end
                    else # else evaluate based on number of vehicles
                        ~,usedVehicles,~ = TotalEvaluation(newVehiclePlan,newCustomerPlan,distDepot,distCustomers)
                        if usedVehicles < currentEvaluation && (i,j) ∉ tabuList
                            currentEvaluation = usedVehicles
                            currentVehiclePlan = newVehiclePlan
                            currentCustomerPlan = newCustomerPlan
                            currentTabu[1] = route[1][3]
                        elseif usedVehicles < currentEvaluation && usedVehicles < bestSolution # aspiration level (ignore Tabu list if better than overal best)
                            currentEvaluation = usedVehicles
                            currentVehiclePlan = newVehiclePlan
                            currentCustomerPlan = newCustomerPlan
                            currentTabu[1] = route[1][3]
                        end
                    end
                end
            end
        end
    end
    println(currentEvaluation)
    return currentVehiclePlan,currentCustomerPlan,currentTabu,currentEvaluation
end

function RunOrOpt(h,k,I,maxLength,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan)
    bestEvaluation = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)[1]
    tabuList = [(1000,1000) for i = 1:k] # initialize tabu list

    i = 0
    while i < I
        vehiclePlan,customerPlan,currentTabu,evaluation = BestOrOpt(h,tabuList,true,maxLength,s,Q,bestEvaluation,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
        tabuList = vcat(tabuList[2:end],currentTabu)

        if evaluation < bestEvaluation
            i = 0
            bestEvaluation = evaluation
            bestVehiclePlan = vehiclePlan
            bestCustomerPlan = customerPlan
        else
            i += 1
        end
    end
    return vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan
end
