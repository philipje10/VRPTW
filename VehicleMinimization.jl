using Random

function AllowedSwitches(vehiclePlan)
    correspondingRoute = Int32[]
    shortestRoute = 10^10
    for r  = 1:length(vehiclePlan)
        if vehiclePlan[r][1] != Float32 && vehiclePlan[r][1] != 0
            if length(vehiclePlan[r][2]) < shortestRoute
                shortestRoute = length(vehiclePlan[r][2])
                correspondingRoute = Int32[r]
            elseif length(vehiclePlan[r][2]) == shortestRoute
                push!(correspondingRoute,r)
            end
        end
    end
    allowedSwitches = Int32[]
    for route in correspondingRoute
        for location in vehiclePlan[route][2][2:end-1]
            push!(allowedSwitches,location)
        end
    end
    return allowedSwitches
end


function MinimizeVehicles(h,s,Q,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    allowedSwitches = AllowedSwitches(vehiclePlan)

    for i in allowedSwitches
        neighbours = FindNeighbours(i,distCustomers,customerPlan,199)
        for j in neighbours
            if j ∉ allowedSwitches
                newRoutes = OrOptSwitch(i,j,1,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                for route in newRoutes
                    newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                    if newCustomerPlan != false
                        newVehiclePlan = deepcopy(vehiclePlan)
                        newVehiclePlan[route[1][2]] = route[1][1]
                        newVehiclePlan[route[2][2]] = route[2][1]
                        println("minimize min route")
                        return newVehiclePlan,newCustomerPlan
                    end
                end
            end
        end
    end
    residuals = shuffle!([i for i = 1:C if i ∉ allowedSwitches]) # Shuffle to add randomness
    if rand()<= 0.5
        for i in residuals
            neighbours = shuffle!(FindNeighbours(i,distCustomers,customerPlan,h))
            for j in neighbours
                if j ∉ allowedSwitches
                    newRoutes = OrOptSwitch(i,j,1,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                    for route in newRoutes
                        newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                        if newCustomerPlan != false
                            newVehiclePlan = deepcopy(vehiclePlan)
                            newVehiclePlan[route[1][2]] = route[1][1]
                            newVehiclePlan[route[2][2]] = route[2][1]
                            println("random move")
                            return newVehiclePlan,newCustomerPlan
                        end
                    end
                end
            end
        end
        return false,false
    else
        for i in residuals
            neighbours = shuffle!(FindNeighbours(i,distCustomers,customerPlan,h))
            for j in neighbours
                if j ∉ allowedSwitches
                    newRoutes = TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                    newCustomerPlan = CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                    if newCustomerPlan != false
                        newVehiclePlan = deepcopy(vehiclePlan)
                        newVehiclePlan[newRoutes[1][2]] = newRoutes[1][1]
                        newVehiclePlan[newRoutes[2][2]] = newRoutes[2][1]
                        println("random move")
                        return newVehiclePlan,newCustomerPlan
                    end
                end
            end
        end
    end
    return false,false
end
