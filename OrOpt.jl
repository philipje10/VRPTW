include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")
include("2Opt.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,5,1)

function OrOptSwitch(i,j,maxLength,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
    deltaVehicles = 0
    deltaDistance = 0
    vehicleA = customerPlan[i][1]
    vehicleB = customerPlan[j][1]
    oldRouteA = vehiclePlan[vehicleA][2]
    oldRouteB = vehiclePlan[vehicleB][2]
    capacityB = vehiclePlan[vehicleB][1]
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
        deltaVehicles = 0
        deltaDistance = 0

        swappedLocations = oldRouteA[cutPointA:cutPointA + p - 1]
        capacityB += sum(customerDemand[i] for i in swappedLocations)
        if capacityB > Q
            push!(newRoutes, false)
        else
            newRouteA = vcat(oldRouteA[1:cutPointA - 1], oldRouteA[cutPointA + p:end])
            newRouteB = vcat(oldRouteB[1:cutPointB], swappedLocations ,oldRouteB[cutPointB+1:end])

            deltaLocationsA = oldRouteA[cutPointA - 1:cutPointA + p]
            deltaLocationsB = vcat(oldRouteB[cutPointB],swappedLocations,oldRouteB[cutPointB+1])
            deltaDistanceA = Distance(oldRouteA[cutPointA - 1],oldRouteA[cutPointA + p],distDepot,distCustomers) - sum(Distance(deltaLocationsA[i-1],deltaLocationsA[i],distDepot,distCustomers) for i = 2:length(deltaLocationsA))
            deltaDistanceB = sum(Distance(deltaLocationsB[i-1],deltaLocationsB[i],distDepot,distCustomers) for i = 2:length(deltaLocationsB)) - Distance(oldRouteB[cutPointB],oldRouteB[cutPointB+1],distDepot,distCustomers)
            deltaDistance = deltaDistanceA + deltaDistanceB
            if length(newRouteA) > 2
                capacityA = sum(customerDemand[i] for i in newRouteA[2:end-1])
            else
                newRouteA = [0]
                capacityA = 0
                deltaVehicles += -1
            end
            push!(newRoutes,[([Float32(capacityA),newRouteA],vehicleA,tabu,deltaVehicles,deltaDistance),([Float32(capacityB),newRouteB],vehicleB,tabu,deltaVehicles,deltaDistance)])
        end
    end
    return newRoutes
end

function BestOrOpt(h,tabuList,distanceEvaluation,maxLength,s,Q,bestSolution,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    currentEvaluation = 10^10
    originalDistance,originalVehicles,~ = TotalEvaluation(vehiclePlan,customerPlan,distDepot,distCustomers)
    currentVehiclePlan = vehiclePlan
    currentCustomerPlan = customerPlan
    currentTabu = [(1000,1000)]
    for i = 1:C
        neighbours = FindNeighbours(i,distCustomers,customerPlan,h)
        for j in neighbours
            newRoutes = OrOptSwitch(i,j,maxLength,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
            for route in newRoutes
                newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                if newCustomerPlan != false
                    newVehiclePlan = deepcopy(vehiclePlan)
                    newVehiclePlan[route[1][2]] = route[1][1]
                    newVehiclePlan[route[2][2]] = route[2][1]
                    if distanceEvaluation == true
                        # totalDistance,~,~ = TotalEvaluation(newVehiclePlan,newCustomerPlan,distDepot,distCustomers)
                        totalDistance = originalDistance + route[1][5] # Delta evaluation
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
                        # ~,usedVehicles,~ = TotalEvaluation(newVehiclePlan,newCustomerPlan,distDepot,distCustomers)
                        usedVehicles = originalVehicles + route[1][4]
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

function RunOrOpt(h,k,I,maxLength,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuList)
    bestEvaluation = TotalEvaluation(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)[1]

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
    return vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuList
end
