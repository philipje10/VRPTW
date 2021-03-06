using Luxor
using DataFrames
using Random
using CSV

"""Checks route for feasibility based on three measures: (1) the maximum capacity,
(2) the travel time must be respected, and (3) the customer time windows must be respected"""
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

"""Checks if the solution is feasible, based on the feasibility of the routes"""
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

"""Given a customer i, returns the h nearest neighbours"""
function FindNeighbours(i,distCustomers,customerPlan,vehiclePlan,h) # h is number of neighbours
    C = length(customerPlan)
    distanceList = [(Float32(0.0),Int32(0)) for j = 1:C]
    for j = 1:C
        distanceList[j] = (distCustomers[i,j],j)
    end
    m = length(vehiclePlan[customerPlan[i][1]][2])-2 # Minus two times the depot
    distanceList = sort(distanceList)
    neighbours = zeros(Int32,min(h,C-m))
    j = Int32(1)
    index = Int32(1)
    while j <= C && index <= h
        if customerPlan[distanceList[j][2]][1] != customerPlan[i][1]
            neighbours[index] = distanceList[j][2]
            index += 1
        end
        j += 1
    end
    return neighbours
end

"""Given new routes, creates a new customerplan with the arrival, service,
and departure times adjusted, and with the correct vehicle number"""
function CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
    newCustomerPlan = deepcopy(customerPlan)
    if newRoutes == false
        return false
    else
        for r in newRoutes
            route = r[1]
            vehicle = r[2]
            for c = 2:(length(route[2])-1)
                i = route[2][c-1]
                j = route[2][c]
                if i == 0
                    e_i = 0
                    s_i = 0
                    t_i = depotTimes[1]
                    newCustomerPlan[j][2][2] = t_i + s_i + BetweenTime(i,j,s,depotTimes,customerTimes,newCustomerPlan,distDepot,distCustomers)
                    newCustomerPlan[j][2][1] = newCustomerPlan[j][2][2]
                else
                    e_i = customerTimes[i,1]
                    s_i = s
                    t_i = newCustomerPlan[i][2][2]
                    newCustomerPlan[j][2][1] = t_i + s_i + Distance(i,j,distDepot,distCustomers)
                    newCustomerPlan[j][2][2] = t_i + s_i + BetweenTime(i,j,s,depotTimes,customerTimes,newCustomerPlan,distDepot,distCustomers)
                end
                newCustomerPlan[j][1] = vehicle # Assign truck to customer
                newCustomerPlan[j][2][3] = newCustomerPlan[j][2][2] + s
                if newCustomerPlan[j][2][2] > customerTimes[j,2] || newCustomerPlan[j][2][2] < customerTimes[j,1]
                    return false
                end
            end
        end
    end
    return newCustomerPlan
end

"""Evaluates the route for the three KPI's: (1) distance, (2) waiting time, and (3) capacity"""
function RouteEvaluation(route,customerPlan,distDepot,distCustomers)
    distance = 0
    waitingTime = 0
    capacity = route[1]
    for c = 2:length(route[2])
        i = route[2][c-1]
        j = route[2][c]
        distance += Distance(i,j,distDepot,distCustomers)
        if j != 0
            waitingTime += (customerPlan[j][2][2] - customerPlan[j][2][1])
        end
    end
    return distance,waitingTime,capacity
end

"""Uses the route evaluation to create aggregated evaluation values"""
function TotalEvaluation(vehiclePlan,customerPlan,instance)
    ~,~,~,depotCoordinates,~,customerCoordinates,~,~,~ = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
    totalDistance = 0
    usedVehicles = 0
    totalWaitingTime = 0
    for route in vehiclePlan
        if route[1] != Float32 && route[1] != 0
            usedVehicles += 1
            distance,waitingTime,~ = RouteEvaluation(route,customerPlan,distDepot,distCustomers)
            totalDistance += distance
            totalWaitingTime += waitingTime
        end
    end
    return round(totalDistance,digits = 4),usedVehicles,round(totalWaitingTime,digits = 4)
end

"""Function that only returns the distance. Function meant to call inside loops"""
function TotalDistance(vehiclePlan,customerPlan,distDepot,distCustomers)
    totalDistance = 0
    for route in vehiclePlan
        if route[1] != Float32 && route[1] != 0
            distance,~,~ = RouteEvaluation(route,customerPlan,distDepot,distCustomers)
            totalDistance += distance
        end
    end
    return round(totalDistance,digits = 4)
end

"""Function that only returns the vehicles. Function meant to call inside loops"""
function UsedVehicles(vehiclePlan)
    usedVehicles = 0
    for route in vehiclePlan
        if route[1] != Float32 && route[1] != 0
            usedVehicles += 1
        end
    end
    return usedVehicles
end

"""Function that chooses a random element from an array"""
function ChooseRandom(array)
    if isempty(array)
        return nothing
    else
        n = length(array)
        idx = rand(1:n)
        return array[idx]
    end
end

"""Translates the time value in dataframe to difference time between start algorithm
and findings of that specific value"""
function CorrectTime(startTime,x)
    return round((x - startTime)/1e9,digits=3)
end

"""Given a number of locations and allowed switches, returns a vehicle and customer plan
with random changes in the route (if and only if they remain feasible). The random function
determines whether the or-opt or 2-opt operator is applied"""
function RandomMove(locations,allowedSwitches,h,Q,s,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers,depotTimes,customerTimes)
    shuffle!(locations)
    if rand()<= 0.5
        for i in locations
            neighbours = shuffle!(FindNeighbours(i,distCustomers,customerPlan,vehiclePlan,h))
            for j in neighbours
                if j ∉ allowedSwitches
                    newRoutes = OrOptSwitch(i,j,1,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                    for route in newRoutes
                        newCustomerPlan = CreateNewPlans(route,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                        if newCustomerPlan != false
                            newVehiclePlan = deepcopy(vehiclePlan)
                            newVehiclePlan[route[1][2]] = route[1][1]
                            newVehiclePlan[route[2][2]] = route[2][1]
                            return newVehiclePlan,newCustomerPlan
                        end
                    end
                end
            end
        end
    else
        for i in locations
            neighbours = shuffle!(FindNeighbours(i,distCustomers,customerPlan,vehiclePlan,h))
            for j in neighbours
                if j ∉ allowedSwitches
                    newRoutes = TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand,distDepot,distCustomers)
                    newCustomerPlan = CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
                    if newCustomerPlan != false
                        newVehiclePlan = deepcopy(vehiclePlan)
                        newVehiclePlan[newRoutes[1][2]] = newRoutes[1][1]
                        newVehiclePlan[newRoutes[2][2]] = newRoutes[2][1]
                        return newVehiclePlan,newCustomerPlan
                    end
                end
            end
        end
    end
end

function PlotSolution(vehiclePlan,instance,imageName)
    format = 160
    scale = 10
    ~,~,C,depotCoordinates,~,customerCoordinates,~,~,~ = ReadInstance(instance)
    Drawing(format*scale, format*scale,imageName)
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

"""Prints every route as a dataframe, including exact arrival, service, and departure times,
including waiting times and the route evaluation"""
function PrintSolution(vehiclePlan,customerPlan,instance)
    ~,~,~,depotCoordinates,depotTimes,customerCoordinates,~,customerTimes,~ = ReadInstance(instance)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)
    r = 0
    for route in vehiclePlan
        if route[1] != Float32 && route[1] != 0
            df = DataFrame(Loc = Int[], Arr = Any[], Wait = Any[], Serv = Any[], Dep = Any[], Open = Int[], Close = Int[])
            r += 1
            Loc = nothing
            Arr = nothing
            Serv = nothing
            Wait = nothing
            Dep = nothing
            Open = nothing
            Close = nothing
            distance,waitingTime,capacity = RouteEvaluation(route,customerPlan,distDepot,distCustomers)
            println("\n")
            println("Route: ",r)
            println("-----------")
            println("Total distance: ",round(distance,digits = 2))
            println("Total waiting time: ", round(waitingTime,digits = 2))
            println("Capacity utilization: ",capacity,"\n")
            for c = 1:length(route[2])
                i = route[2][c]
                if c == 1
                    Loc = 0
                    Arr = "-"
                    Serv = "-"
                    Wait = "-"
                    Dep = abs(round(customerPlan[route[2][2]][2][1]-distDepot[route[2][2]],digits = 2))
                    Open = depotTimes[1]
                    Close = depotTimes[2]
                elseif c == length(route[2])
                    Loc = 0
                    Arr = abs(round(customerPlan[route[2][length(route[2])-1]][2][3]+distDepot[route[2][length(route[2])-1]],digits = 2))
                    Serv = "-"
                    Wait = "-"
                    Dep = "-"
                    Open = depotTimes[1]
                    Close = depotTimes[2]
                else
                    Loc = i
                    Arr = round(customerPlan[i][2][1],digits = 2)
                    Serv = round(customerPlan[i][2][2],digits = 2)
                    Wait = round(Serv - Arr,digits = 2)
                    Dep = round(customerPlan[i][2][3],digits = 2)
                    Open = customerTimes[i,1]
                    Close = customerTimes[i,2]
                end
                push!(df,[Loc,Arr,Wait,Serv,Dep,Open,Close])
            end
            print(df,"\n")
        end
    end
end
