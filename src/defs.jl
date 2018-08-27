# common definitions


const sourcePath = @__DIR__


# run modes
const debugMode = false
const checkMode = true # for data checking, e.g. assertions that are checked frequently

# file chars
const delimiter = ','
const newline = "\r\n"

# misc null values
nullFunction() = nothing

const nullTime = -1.0
const nullDist = -1.0


@enum MachineType nullMachineType=0 workStation=1 robot=2

@enum ProductType nullProductType chair table
