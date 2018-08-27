__precompile__()
module FactorySim

importall JEMSS

# animation
using HttpServer
using WebSockets
using JSON

# files
using LightXML

# optimisation (move-up)
using JuMP
using GLPKMathProgInterface # does not use precompile

# statistics
using Distributions
using HypothesisTests
using Stats
using StatsFuns

# misc
using LightGraphs
using ArchGDAL # does not use precompile
using JLD
import Plots

export
    runFactConfig, makeFactoryArcs, makeFactoryNodes, readLocationsFile, fact_animate

export
    decompose_order

export
    Job, Batch, Schedule, ProductOrder

export
    MachineType, nullMachineType, workStation, robot,
    ProductType, nullProductType, chair, table


include("defs.jl")

include("types/types.jl")
include("types/order.jl")

include("animation/fact_animation.jl")

include("gen_fact_sim_files.jl")


end
