include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)
distDepot,distCustomers = DistanceMatrix(depotCoordinates,customerCoordinates)

customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)
SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)

# PlotSolution(vehiclePlan,160,10,instance)

# 2-opt*
function FindNeighbours(i,distCustomers,customerPlan,h) # h is number of neighbours
    distanceList = Tuple{Float32,Int32}[]
    for j = 1:C
        push!(distanceList,(distCustomers[i,j],j))
    end
    distanceList = sort(distanceList)
    neighbours = Int32[]
    j = 1
    while length(neighbours) < h && j <= C
        if customerPlan[distanceList[j][2]][1] != customerPlan[i][1]
            push!(neighbours,distanceList[j][2])
        end
        j += 1
    end
    return neighbours
end


function TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand) #j = j + 1
    vehicleA = customerPlan[i][1]
    vehicleB = customerPlan[j][1]
    oldRouteA = vehiclePlan[vehicleA][2]
    oldRouteB = vehiclePlan[vehicleB][2]
    cutPointA = 1
    cutPointB = 1
    c = nothing

    while oldRouteA[cutPointA] != i
        cutPointA += 1
    end

    while oldRouteB[cutPointB] != j
        cutPointB += 1
    end

    newRouteA = vcat(oldRouteA[1:cutPointA], oldRouteB[cutPointB:end])
    newRouteB = vcat(oldRouteB[1:cutPointB-1], oldRouteA[cutPointA+1:end])
    if length(newRouteA) > 2
        capacityA = sum(customerDemand[i] for i in newRouteA[2:end-1])
    else
        capacityA = 0
    end
    if length(newRouteB) > 2
        capacityB = sum(customerDemand[i] for i in newRouteB[2:end-1])
    else
        capacityB = 0
    end

    if capacityA > Q || capacityB > Q
        return false
    else
        return [([Float32(capacityA),newRouteA],vehicleA),([Float32(capacityB),newRouteB],vehicleB)]
    end
end

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


# neighbours = FindNeighbours(1,distCustomers,customerPlan,10)
# newRoutes = TwoOptSwitch(42,170,Q,customerPlan,vehiclePlan,customerDemand)
# newCustomerPlan = CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)

tmp = []
for i = 1:C
    neighbours = FindNeighbours(i,distCustomers,customerPlan,10)
    for j in neighbours
        newRoutes = TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand)
        newCustomerPlan = CreateNewPlans(newRoutes,customerPlan,s,depotTimes,customerTimes,distDepot,distCustomers)
        if newCustomerPlan != false
            push!(tmp,[(i,j),newCustomerPlan])
        end
    end
end

# To do: Check for empty routes
