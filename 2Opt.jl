function TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers) #j = j + 1
    deltaVehicles = 0
    deltaDistance = 0
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

    tabuA = (oldRouteA[cutPointA],oldRouteA[cutPointA+1])
    tabuB = (oldRouteB[cutPointB-1],oldRouteB[cutPointB])

    newRouteA = vcat(oldRouteA[1:cutPointA], oldRouteB[cutPointB:end])
    newRouteB = vcat(oldRouteB[1:cutPointB-1], oldRouteA[cutPointA+1:end])
    if length(newRouteA) > 2
        capacityA = sum(customerDemand[i] for i in newRouteA[2:end-1])
    else
        newRouteA = [0]
        capacityA = 0
    end
    if length(newRouteB) > 2
        capacityB = sum(customerDemand[i] for i in newRouteB[2:end-1])
    else
        newRouteB = [0]
        capacityB = 0
    end

    if capacityA > Q || capacityB > Q
        return false
    else
        deltaDistanceA = Distance(oldRouteA[cutPointA],oldRouteB[cutPointB],distDepot,distCustomers) - Distance(oldRouteA[cutPointA],oldRouteA[cutPointA+1],distDepot,distCustomers)
        deltaDistanceB = Distance(oldRouteB[cutPointB-1],oldRouteA[cutPointA+1],distDepot,distCustomers) - Distance(oldRouteB[cutPointB-1],oldRouteB[cutPointB],distDepot,distCustomers)
        deltaDistance = deltaDistanceA + deltaDistanceB
        return [([Float32(capacityA),newRouteA],vehicleA,tabuA,deltaDistance),([Float32(capacityB),newRouteB],vehicleB,tabuB,deltaDistance)]
    end
end

function BestTwoOpt(h,C,tabuList,s,Q,bestSolution,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    currentEvaluation = 10^10
    originalDistance = TotalDistance(vehiclePlan,customerPlan,distDepot,distCustomers)
    currentVehiclePlan = vehiclePlan
    currentCustomerPlan = customerPlan
    currentTabu = [(1000,1000),(1000,1000)]
    for i = 1:C
        neighbours = FindNeighbours(i,distCustomers,customerPlan,vehiclePlan,h)
        for j in neighbours
            newRoutes = TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
            newCustomerPlan = CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
            if newCustomerPlan != false
                totalDistance = originalDistance + newRoutes[1][4] # Delta evaluation
                if totalDistance < currentEvaluation && (i,j) ∉ tabuList
                    newVehiclePlan = deepcopy(vehiclePlan)
                    newVehiclePlan[newRoutes[1][2]] = newRoutes[1][1]
                    newVehiclePlan[newRoutes[2][2]] = newRoutes[2][1]

                    currentEvaluation = totalDistance
                    currentVehiclePlan = newVehiclePlan
                    currentCustomerPlan = newCustomerPlan
                    currentTabu[1] = newRoutes[1][3]
                    currentTabu[2] = newRoutes[2][3]
                elseif totalDistance < currentEvaluation && totalDistance < bestSolution # aspiration level (ignore Tabu list if better than overal best)
                    newVehiclePlan = deepcopy(vehiclePlan)
                    newVehiclePlan[newRoutes[1][2]] = newRoutes[1][1]
                    newVehiclePlan[newRoutes[2][2]] = newRoutes[2][1]

                    currentEvaluation = totalDistance
                    currentVehiclePlan = newVehiclePlan
                    currentCustomerPlan = newCustomerPlan
                    currentTabu[1] = newRoutes[1][3]
                    currentTabu[2] = newRoutes[2][3]
                end
            end
        end
    end
    println(currentEvaluation)
    return currentVehiclePlan,currentCustomerPlan,currentTabu,currentEvaluation
end

function RunTwoOpt(h,s,C,Q,I,vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers,depotTimes,customerTimes,customerDemand,tabuList)
    bestEvaluation = TotalDistance(bestVehiclePlan,bestCustomerPlan,distDepot,distCustomers)
    results = Float64[]

    i = 0
    while i < I
        vehiclePlan,customerPlan,currentTabu,evaluation = BestTwoOpt(h,C,tabuList,s,Q,bestEvaluation,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
        tabuList = vcat(tabuList[3:end],currentTabu)
        push!(results,evaluation)

        if evaluation < bestEvaluation
            i = 0
            bestEvaluation = evaluation
            bestVehiclePlan = vehiclePlan
            bestCustomerPlan = customerPlan
        else
            i += 1
        end
    end
    trend = (results[end] - results[1])/length(results)

    return vehiclePlan,customerPlan,bestVehiclePlan,bestCustomerPlan,tabuList,trend
end
