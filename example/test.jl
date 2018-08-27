using FactorySim

job_dict = Dict{FactorySim.ProductType,Array{FactorySim.Job,1}}()
jobs=[]
for i= 1:3
    push!(jobs,Job())
    jobs[i].machineType = workStation
end
jobs[2].machineType = robot
job_dict[chair] = jobs
jobs=[]
for i= 1:4
    push!(jobs,Job())
    jobs[i].machineType = workStation
end
jobs[3].machineType = robot
job_dict[table]=jobs

orderlist = Vector{ProductOrder}()
order=ProductOrder()
order.size = 280
order.product=table
push!(orderlist,order)
order2=ProductOrder()
order2.size = 40
order2.product=chair
push!(orderlist,order2)

orderlist
job_dict

batchlist = decompose_order(orderlist,Int(50),job_dict)
for batch in batchlist
    print(batch.index,',',batch.size,',',length(batch.toDo),'\n')
end
