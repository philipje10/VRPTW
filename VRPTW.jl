include("Filereader.jl")
include("InitialSolution.jl")
include("HelpFunctions.jl")

instance = "data/C1_2_1.TXT"

K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s = ReadInstance(instance)

customerPlan, vehiclePlan, unvisitedCustomers = InitialSolutionBuilder(instance,1,1)
SolutionCheck(customerPlan,vehiclePlan,unvisitedCustomers,instance)

# PlotSolution(vehiclePlan,160,10,instance)

# 2-opt*

function TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand)
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
    capacityA = sum(customerDemand[i] for i in newRouteA[2:end-1])
    capacityB = sum(customerDemand[i] for i in newRouteB[2:end-1])

    if capacityA > Q || capacityB > Q
        return false,false
    else
        return [Float32(capacityA),Int32[newRouteA]],[Float32(capacityB),Int32[newRouteB]]
    end
end


i = 43
j = 64 # (j+1)

A,B = TwoOptSwitch(i,j,Q,customerPlan,vehiclePlan,customerDemand)
