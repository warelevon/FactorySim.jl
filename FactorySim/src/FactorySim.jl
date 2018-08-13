__precompile__()
module FactorySim

importall JEMSS
using LightGraphs
using LightXML
using Stats
using Distributions

export
    runFactConfig


include("gen_fact_sim_files.jl")
include("animation.jl")


end
