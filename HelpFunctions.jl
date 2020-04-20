using Luxor

function RouteCheck(Route,Q,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,distDepot,distCustomers)
    routeFeasibility = true
    if Route[1] > Q    # capacity check
        routeFeasibility = routeFeasibility * false
    end
    for i = 2:length(Route[2])
        departLocation = Route[2][i-1]
        arriveLocation = Route[2][i]
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
            routeFeasibility = routeFeasibility * false
        end
        if serviceTime < earliestTime || serviceTime > latestTime # service within time window
            routeFeasibility = routeFeasibility * false
        end
    end
    return routeFeasibility
end

function SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)
    ~,Q,~,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,~ = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)

    feasibleRoute = Bool[true for r = 1:CurrentVehicle(vehiclePlan)]
    for r = 1:CurrentVehicle(vehiclePlan)
        Route = vehiclePlan[r]
        feasibleRoute[r] = RouteCheck(Route,Q,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,distDepot,distCustomers)
    end
    if ((count(x -> x = true,feasibleRoute) == CurrentVehicle(vehiclePlan)) && (length(unvisitedCustomers) == 0))
        print("The solution is feasible")
    else
        print("The solution is not feasible")
    end
end

function PlotSolution(vehiclePlan,format,scale,instance)
    ~,~,C,depotCoordinates,~,customerCoordinates,~,~,~ = ReadInstance(instance)
    Drawing(format*scale, format*scale)
    background("white")
    origin((format/2)*scale,(format/2)*scale)

    sethue("black")
    for r = 1:length(vehiclePlan)
        for i = 2:length(vehiclePlan[r][2])
            departLocation = vehiclePlan[r][2][i-1]
            arriveLocation = vehiclePlan[r][2][i]
            if departLocation == 0
                x_d = 0
                y_d = 0
            else
                x_d = customerCoordinates[departLocation,1]-depotCoordinates[1]
                y_d = customerCoordinates[departLocation,2]-depotCoordinates[1]
            end
            if arriveLocation == 0
                x_a = 0
                y_a = 0
            else
                x_a = customerCoordinates[arriveLocation,1]-depotCoordinates[1]
                y_a = customerCoordinates[arriveLocation,2]-depotCoordinates[1]
            end
            line(Point(x_d,y_d)*scale, Point(x_a,y_a)*scale, :stroke)
        end
    end

    sethue("blue")
    for i = 1:C
        x = (customerCoordinates[i,1]-depotCoordinates[1])*scale
        y = (customerCoordinates[i,2]-depotCoordinates[2])*scale
        circle(Point(x,y),10, :fill)
    end

    sethue("red")
    x = 0
    y = 0
    box(Point(x,y),20 , 20, vertices=false,:fill)

    finish()
    return preview()
end
