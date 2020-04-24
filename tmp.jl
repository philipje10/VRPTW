for i = 1:C
    neighbours = FindNeighbours(i,distCustomers,customerPlan,10)
    for j in neighbours
