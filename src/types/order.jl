function decompose_order(orderList::Vector{ProductOrder},maxBatchSize::Int,job_dict::Dict{ProductType,Vector{Job}})
    batchList = []
    j=1
    for order in orderList
        while order.size> 0
            batch = Batch(j,job_dict[order.product],order.dueTime)
            batch.size = order.size>maxBatchSize ? maxBatchSize : order.size
            order.size -= batch.size
            push!(batchList,batch)
            j += 1
        end
    end
    return batchList
end
