function ReadInstance(filename)
    file = open(filename)
    instance = readline(file)
    readline(file),readline(file),readline(file)
    vehicle = split(readline(file))
    K = parse(Int,vehicle[1])
    Q = parse(Int,vehicle[2])
    C = 200
    readline(file),readline(file),readline(file),readline(file)
    depot = split(readline(file))
    depotCoordinates = zeros(Int64,2)
    depotTimes = zeros(Int64,2)
    depotCoordinates[1] = parse(Int,depot[2])
    depotCoordinates[2] = parse(Int,depot[3])
    depotTimes[1] = parse(Int,depot[5])
    depotTimes[2] = parse(Int,depot[6])
    customerCoordinates = zeros(Int64,C,2)
    customerDemand = zeros(Int64,C)
    customerTimes = zeros(Int64,C,2)
    s = Int32
    for i = 1:C
        customer = split(readline(file))
        customerCoordinates[i,1] = parse(Int,customer[2])
        customerCoordinates[i,2] = parse(Int,customer[3])
        customerDemand[i] = parse(Int,customer[4])
        customerTimes[i,1] = parse(Int,customer[5])
        customerTimes[i,2] = parse(Int,customer[6])
        s = parse(Int,customer[7])
    end
    return K,Q,C,depotCoordinates,depotTimes,customerCoordinates,customerDemand,customerTimes,s
end

function DistanceMatrix(depotCoordinates,customerCoordinates)
    C = size(customerCoordinates)[1]
    distDepot = zeros(Float64,C)
    distCustomers = zeros(Float64,C,C)
    for i = 1:C
        x1,y1,x2,y2 = depotCoordinates[1],depotCoordinates[2],customerCoordinates[i,1],customerCoordinates[i,2]
        distDepot[i] = round(((x1-x2)^2 + (y1-y2)^2)^(1/2),digits = 4)
    end
    for i = 1:C, j = 1:C
        x1,y1,x2,y2 = customerCoordinates[i,1],customerCoordinates[i,2],customerCoordinates[j,1],customerCoordinates[j,2]
        distCustomers[i,j] = round(((x1-x2)^2 + (y1-y2)^2)^(1/2),digits = 4)
    end
    return distDepot,distCustomers
end
