@agent Wolf GridAgent{2} begin
    energy::Float64
    reproduction_prob::Float64
    Δenergy::Float64
end

@agent Sheep GridAgent{2} begin
    energy::Float64
    reproduction_prob::Float64
    Δenergy::Float64
end

function predator_prey(;
    n_sheep = 60,
    n_wolves = 40,
    dims = (25, 25),
    regrowth_time = 20,
    Δenergy_sheep = 5,
    Δenergy_wolf = 13,
    sheep_reproduce = 0.2,
    wolf_reproduce = 0.1,
)
    space = GridSpace(dims, periodic = false)
    properties = (
        fully_grown = falses(dims),
        countdown = zeros(Int, dims),
        regrowth_time = regrowth_time,
    )
    model = ABM(
        Union{Wolf, Sheep},
        space,
        scheduler = Schedulers.ByType(true, true, Union{Wolf, Sheep}),
        properties = properties,
        warn=false
    )
    id = 0
    for _ in 1:n_sheep
        id += 1
        energy = rand(1:(Δenergy_sheep*2)) - 1
        sheep = Sheep(id, (0, 0), energy, sheep_reproduce, Δenergy_sheep)
        add_agent!(sheep, model)
    end
    for _ in 1:n_wolves
        id += 1
        energy = rand(1:(Δenergy_wolf*2)) - 1
        wolf = Wolf(id, (0, 0), energy, wolf_reproduce, Δenergy_wolf)
        add_agent!(wolf, model)
    end
    for p in positions(model) # random grass initial growth
        fully_grown = rand(abmrng(model), Bool)
        countdown = fully_grown ? regrowth_time : rand(abmrng(model), 1:regrowth_time) - 1
        model.countdown[p...] = countdown
        model.fully_grown[p...] = fully_grown
    end
    return model, agent_step!, model_step!
end

function agent_step!(sheep::Sheep, model)
    randomwalk!(sheep, model, 1)
    sheep.energy -= 1
    sheep_eat!(sheep, model)
    if sheep.energy < 0
        kill_agent!(sheep, model)
        return
    end
    if rand(abmrng(model)) <= sheep.reproduction_prob
        reproduce!(sheep, model)
    end
end

function agent_step!(wolf::Wolf, model)
    randomwalk!(wolf, model, 1)
    wolf.energy -= 1
    agents = agents_in_position(wolf.pos, model)
    dinner = Iterators.filter(x -> typeof(x) == Sheep, agents)
    wolf_eat!(wolf, dinner, model)
    if wolf.energy < 0
        kill_agent!(wolf, model)
        return
    end
    if rand(abmrng(model)) <= wolf.reproduction_prob
        reproduce!(wolf, model)
    end
end

function sheep_eat!(sheep, model)
    if model.fully_grown[sheep.pos...]
        sheep.energy += sheep.Δenergy
        model.fully_grown[sheep.pos...] = false
    end
end

function wolf_eat!(wolf, sheep, model)
    if !isempty(sheep)
        dinner = rand(abmrng(model), collect(sheep))
        kill_agent!(dinner, model)
        wolf.energy += wolf.Δenergy
    end
end

function reproduce!(agent, model)
    agent.energy /= 2
    offspring = typeof(agent)(
        nextid(model),
        agent.pos,
        agent.energy,
        agent.reproduction_prob,
        agent.Δenergy,
    )
    add_agent_pos!(offspring, model)
    return
end

function model_step!(model)
    @inbounds for p in positions(model)
        if !(model.fully_grown[p...])
            if model.countdown[p...] ≤ 0
                model.fully_grown[p...] = true
                model.countdown[p...] = model.regrowth_time
            else
                model.countdown[p...] -= 1
            end
        end
    end
end
