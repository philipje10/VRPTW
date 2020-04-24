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


neighbours = FindNeighbours(1,distCustomers,customerPlan,15)
i = 132
j = 9
maxLength = 3
newRoutes = OrOptSwitch(i,j,maxLength,Q,customerPlan,vehiclePlan,customerDemand)
