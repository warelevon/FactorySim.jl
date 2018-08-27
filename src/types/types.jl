type Job

    index::Integer
    batchIndex::Integer
    machineType::MachineType

    withWorker::Float
    withoutWorker::Float
    isComplete::Bool

    Job() = new(nullIndex,nullIndex,nullMachineType,nullTime,nullTime,false)
end

type Batch
    index::Integer
    size::Integer

    toDo::Vector{Job}
    completed::Vector{Job}
    dueTime::Float

    Batch() = new(nullIndex,nullIndex,[],[],nullTime)
    Batch(index::Integer,toDo::Vector{Job},dueTime::Float) = new(index,nullIndex,toDo,[],dueTime)

end

type Schedule

    index::Integer
    numTasks::Integer

    jobList::Vector{Job}

    Schedule() = new(nullIndex,0,[])
end

type ProductOrder
    product::ProductType
    size::Integer
    dueTime::Float

    ProductOrder() = new(nullProductType,nullIndex,nullTime)
    ProductOrder(product::ProductType, size::Integer, dueTime::Float) = new(product,size,dueTime)
end
