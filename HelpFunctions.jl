function SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)
    ~,Q,~,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,~ = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)

    feasibleRoute = Bool[true for r = 1:CurrentVehicle(vehiclePlan)]
    for r = 1:CurrentVehicle(vehiclePlan)
        if vehiclePlan[r][1] > Q    # capacity check
            feasibleRoute[r] = feasibleRoute[r] * false
        end
        tmp = true
        for i = 2:length(vehiclePlan[r][2])
            departLocation = vehiclePlan[r][2][i-1]
            arriveLocation = vehiclePlan[r][2][i]
            if departLocation == 0
                departTime = depotTimes[1]
            else
                departTime = customerPlan[departLocation][2][3]
            end
            if arriveLocation == 0
                arriveTime = departTime + Distance(departLocation,arriveLocation,distDepot,distCustomers)
                serviceTime = departTime + Distance(departLocation,arriveLocation,distDepot,distCustomers)
                earliestTime = depotTimes[1]
                latestTime = depotTimes[2]
            else
                arriveTime = customerPlan[arriveLocation][2][1]
                serviceTime = customerPlan[arriveLocation][2][2]
                earliestTime = customerTimes[arriveLocation,1]
                latestTime = customerTimes[arriveLocation,2]
            end # respected travel time
            if isapprox((arriveTime - departTime) - Distance(departLocation,arriveLocation,distDepot,distCustomers),0,atol = 1e-4) == false && (arriveTime - departTime) < Distance(departLocation,arriveLocation,distDepot,distCustomers)
                feasibleRoute[r] = feasibleRoute[r] * false
            end
            if serviceTime < earliestTime || serviceTime > latestTime # service within time window
                feasibleRoute[r] = feasibleRoute[r] * false
            end
        end
    end
    return ((count(x -> x = true,feasibleRoute) == CurrentVehicle(vehiclePlan)) && (length(unvisitedCustomers) == 0))
end
