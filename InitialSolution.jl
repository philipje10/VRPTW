"""An empty customer and vehicle plan are created based on the number of
customers and on the number of vehicles"""
function InitializePlans(C,K)
    customerPlan = [[Int32,zeros(Float32,3)] for i = 1:C] # [[[truck],[arrival,service,depart]],...,]
    vehiclePlan = [[Float32,Int32[]] for i = 1:K] # [[[used capacity],[route]],...,]
    unvisitedCustomers = Int32[i for i=1:C]
    vehiclePlan[1][1] = 0
    push!(vehiclePlan[1][2],0)
    return customerPlan, vehiclePlan, unvisitedCustomers
end

"""
General notation remark:
e_i = earliest time window of customer i
f_i = latest time window of customer i
s = service time
t_i = actual service time at customer i
"""

"""Translates the distance matrix and distance array to one function"""
function Distance(i,j,distDepot,distCustomers) # distance from i to j
    if i == 0
        if j == 0
            return 0
        else
            return distDepot[j]
        end
    elseif j == 0
        if i == 0
            return 0
        else
            return distDepot[i]
        end
    else
        return distCustomers[i,j]
    end
end

"""Calculates time between the departure from customer i and the service of customer j"""
function BetweenTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers)
    if j ==0
        depotTimes[1]
    else
        e_j = customerTimes[j,1]
    end
    if i == 0
        s_i = 0
        t_i = depotTimes[1]
        e_i = depotTimes[1]
    else
        s_i = s
        t_i = customerPlan[i][2][2]
        e_i = e_i = customerTimes[i,1]
    end
    return max(e_j,max(e_i,t_i)+s_i+Distance(i,j,distDepot,distCustomers)) - (t_i+s_i)
end

"""Calculates time until customer j would be unfeasible on route"""
function UnfeasibleTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers)
    if j == 0
        f_j = depotTimes[2]
    else
        f_j = customerTimes[j,2]
    end
    if i == 0
        s_i = 0
        t_i = depotTimes[1]
        e_i = depotTimes[1]
    else
        s_i = s
        t_i = customerPlan[i][2][2]
        e_i = e_i = customerTimes[i,1]
    end
    return f_j - (t_i + s_i + Distance(i,j,distDepot,distCustomers))
end

"""Returns the evaluation value that determines the next assigned customer to the route.
The notion 'Assessment' has been used to avoid overlap with the evaluation function in
the tabu search"""
function Assessment(i,j,s,distDepot,distCustomers,depotTimes,customerTimes,customerPlan) # Route assessment based on distance, between time, and time till unfeasibility
    return ((1/3) * Distance(i,j,distDepot,distCustomers)
            + (1/3) * BetweenTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers)
            + (1/3) * UnfeasibleTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers))
end

"""Determines which vehicle is currently being filled based on the vehicle plan"""
function CurrentVehicle(vehiclePlan)
    i = 0
    while vehiclePlan[i+1][1] != Float32
        i += 1
    end
    return i
end

"""Checks whether the next customer will be feasible if inserted into the route based on
three criteria: (1) time windows must be satisfied, (2) the vehicle must have sufficient
time to return back to the depot, and (3) capacity cannot be exceeded"""
function FeasibilityCustomer(i,j,s,Q,depotTimes,customerTimes,customerDemand,customerPlan,vehiclePlan,distDepot,distCustomers) # Based on UnfeasibleTime, time to return to depot, and capacity
    Feasibility = UnfeasibleTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers) >= 0
    if i == 0
        s_i = 0
        t_i = depotTimes[1]
        e_i = depotTimes[1]
    else
        s_i = s
        t_i = customerPlan[i][2][2]
        e_i = customerTimes[i,1]
    end
    returnToDepot = t_i + s_i + BetweenTime(i,j,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers) + s + Distance(i,j,distDepot,distCustomers) <= depotTimes[2]
    capacity = vehiclePlan[CurrentVehicle(vehiclePlan)][1] + customerDemand[j] <= Q
    return Feasibility * returnToDepot * capacity
end

"""Returns a list of possible feasible customer locations"""
function PossibleNextLocations(vehiclePlan,unvisitedCustomers,s,Q,depotTimes,customerTimes,distDepot,distCustomers,customerDemand,customerPlan)
    i = vehiclePlan[CurrentVehicle(vehiclePlan)][2][end]
    possibleLocations = Tuple{Float32,Int32}[]
    for j in unvisitedCustomers
        if FeasibilityCustomer(i,j,s,Q,depotTimes,customerTimes,customerDemand,customerPlan,vehiclePlan,distDepot,distCustomers)
            push!(possibleLocations,(Assessment(i,j,s,distDepot,distCustomers,depotTimes,customerTimes,customerPlan),j))
        end
    end
    if isempty(possibleLocations)
        return nothing
    else
        return sort(possibleLocations)
    end
end

"""Chooses the next customer from the possible customers"""
function NextCustomer(options,possibleLocations, unvisitedCustomers)
    if possibleLocations == nothing
        return nothing
    else
        nextCustomer = ChooseRandom(possibleLocations[1:min(length(possibleLocations),options)])
        return nextCustomer[2]
    end
end

"""Updates the customer and vehicle plans after addition of a new customer to a route"""
function UpdatePlans(s,nextCustomer,unvisitedCustomers,vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes,customerDemand)
    # if nothing: Add zero to end route, activate new truck
    if nextCustomer == nothing
        push!(vehiclePlan[CurrentVehicle(vehiclePlan)][2],0)
        push!(vehiclePlan[CurrentVehicle(vehiclePlan)+1][2],0)
        vehiclePlan[CurrentVehicle(vehiclePlan)+1][1] = 0 # New route is active from now on
    # if next: Add customer to route, update capacity, add trucknumber to customerplan, calculate arrival time, service time, departure time
    else
        i = vehiclePlan[CurrentVehicle(vehiclePlan)][2][end]
        if i == 0
            e_i = 0
            s_i = 0
            t_i = depotTimes[1]
            customerPlan[nextCustomer][2][2] = t_i + s_i + BetweenTime(i,nextCustomer,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers)
            customerPlan[nextCustomer][2][1] = customerPlan[nextCustomer][2][2]
        else
            e_i = customerTimes[i,1]
            s_i = s
            t_i = customerPlan[i][2][2]
            customerPlan[nextCustomer][2][2] = t_i + s_i + BetweenTime(i,nextCustomer,s,depotTimes,customerTimes,customerPlan,distDepot,distCustomers)
            customerPlan[nextCustomer][2][1] = t_i + s_i + Distance(i,nextCustomer,distDepot,distCustomers)
        end
        push!(vehiclePlan[CurrentVehicle(vehiclePlan)][2],nextCustomer) # Add customer to route
        vehiclePlan[CurrentVehicle(vehiclePlan)][1] += customerDemand[nextCustomer] # Update capacity
        customerPlan[nextCustomer][1] = CurrentVehicle(vehiclePlan) # Assign truck to customer
        customerPlan[nextCustomer][2][3] = customerPlan[nextCustomer][2][2] + s
        filter!(x -> x != nextCustomer, unvisitedCustomers)
    end
    return unvisitedCustomers,vehiclePlan,customerPlan
end

"""Repeats insertion of customer untill all there are no unvisited customers left"""
function InitialSolutionBuilder(File,Randomization)

    K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(File)
    distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)

    customerPlan, vehiclePlan, unvisitedCustomers = InitializePlans(C,K)
    currentVehicle = CurrentVehicle(vehiclePlan)

    while length(unvisitedCustomers) > 0 && currentVehicle <= K
        possibleLocations = PossibleNextLocations(vehiclePlan,unvisitedCustomers,s,Q,depotTimes,customerTimes,distDepot,distCustomers,customerDemand,customerPlan)
        nextCustomer = NextCustomer(Randomization,possibleLocations, unvisitedCustomers)
        if nextCustomer == nothing && CurrentVehicle(vehiclePlan) == K
            currentVehicle == (K + 1)
            push!(vehiclePlan[CurrentVehicle(vehiclePlan)][2],0)
        else
            unvisitedCustomers,vehiclePlan,customerPlan = UpdatePlans(s,nextCustomer,unvisitedCustomers,vehiclePlan,customerPlan,distDepot,distCustomers,depotTimes,customerTimes,customerDemand)
        end
    end
    push!(vehiclePlan[CurrentVehicle(vehiclePlan)][2],0)
    return customerPlan, vehiclePlan, unvisitedCustomers
end
