using Agents
using BenchmarkTools

include("ForestFire.jl")

a = @benchmark step!(model, agent_step!, model_step!, 100) setup =
    ((model, agent_step!, model_step!) = forest_fire()) samples=100

println("Agents.jl ForestFire (ms): ", minimum(a.times) * 1e-6)

