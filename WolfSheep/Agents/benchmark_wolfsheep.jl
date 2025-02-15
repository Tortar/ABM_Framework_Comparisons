using Agents
using BenchmarkTools

include("WolfSheep.jl")

a = @benchmark step!(model, agent_step!, model_step!, 500) setup = (
    (model, agent_step!, model_step!) = predator_prey()) samples = 100

println("Agents.jl WolfSheep (ms): ", minimum(a.times) * 1e-6)

