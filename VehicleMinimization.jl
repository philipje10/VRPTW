"""Returns a list of allowed switches. Only switches with customers inside
the shortest route are allowed"""
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

"""Function that tries to insert a customer from the shortest route (allowed switch) into
another route. In case there is no possibility of applying an allowed switch (no feasible
options), a random move is applied to create 'space' inside the plan"""
function MinimizeVehicles(h,s,Q,C,customerPlan,vehiclePlan,depotTimes,customerTimes,customerDemand,distCustomers,distDepot)
    global allowedSwitches = AllowedSwitches(vehiclePlan)

    for i in allowedSwitches
        neighbours = FindNeighbours(i,distCustomers,customerPlan,vehiclePlan,199)
        for j in neighbours
            if j ∉ allowedSwitches
                newRoutes = OrOptSwitch(i,j,1,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                for route in newRoutes
                    newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                    if newCustomerPlan != false
                        newVehiclePlan = deepcopy(vehiclePlan)
                        newVehiclePlan[route[1][2]] = route[1][1]
                        newVehiclePlan[route[2][2]] = route[2][1]
                        println("Route minimized")
                        return newVehiclePlan,newCustomerPlan
                    end
                end
            end
        end
    end
    residuals = shuffle!([i for i = 1:C if i ∉ allowedSwitches]) # Shuffle to add randomness
    try # Apply random move if possible
        newVehiclePlan,newCustomerPlan = RandomMove(residuals,allowedSwitches,h,Q,s,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers,depotTimes,customerTimes)
        return newVehiclePlan,newCustomerPlan
    catch # If no random move available, return the old vehicle/customerPlan
        return vehiclePlan,customerPlan
    end
end
