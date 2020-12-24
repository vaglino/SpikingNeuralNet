using LinearAlgebra, SparseArrays, LightGraphs
using Plots, GraphRecipes

## Graph construction

function create_network(n_nodes= 100, k=10, β=0.1)

    if k < log(n_nodes)
        display("should be: n_nodes >> k >> ln(n_nodes)")
    end
     # create small-world network
    g = watts_strogatz(n_nodes, k, β, is_directed=true)
    adjacency = collect(adjacency_matrix(g))

    return g, adjacency
end

function initialize_lengths(adj,lengths=1:10)
    len = adj .* rand(lengths,size(adj))
end


function initialize_weights(adj; p_inhibition)
    W = adj .* rand(Float64,size(adj))

    sign = (rand(Float64,size(adj)) .> p_inhibition) .*2 .-1
    sign = sign .* adj

    W = W .* sign
end


## Network Inference

function take_step(spk)
    spk_mask = spk .!= 0 # find where there is a spike
    spk += spk_mask * stepsize # advance by one step
end

function check_arrival(spk)
    arrived = (spk .≈ len) .* adj
end

function synapse_integration(ΣV, W, x, thresh)
    ΣWx = vec(sum( W .* x , dims = 1))
    ΣV = ΣV * leak + ΣWx
    ŷ = activation.(ΣV, threshold = thresh )

    return ŷ, ΣV
end

function activation(y; threshold=0.5)
    ŷ = tanh(y)
    firing = ŷ > threshold
end

function update_spikes(spk,exc_mask)
    update = zeros(Float64,size(spk))
    update[exc_mask,:] .= adj[exc_mask,:]
    update[spk .!= 0] .= 0
    new_spikes = update
end

function delete_finished_spike(spk,arrived)
    spk_mask = spk .!= 0
    spk[Bool.(arrived)] .= 0
    return spk
end

function  delete_exc_voltage(ΣV, exc_mask)
    ΣV[exc_mask] .= 0.
    return ΣV
end

# function run_inference(spk; maxiters = 100)
#     firing_count = []
#     excited_id = []
#     ΣV = zeros(size(spk,2))
#     for i in 1:maxiters
#         if i == 4
#             @show i
#         end
#         n_firing = sum(spk .!= 0)
#
#         arrived = check_arrival(spk)
#
#         exc_mask, ΣV = synapse_integration(ΣV, W, arrived, thresh)
#
#         new_spikes = update_spikes(spk,exc_mask)
#
#         spk = delete_finished_spike(spk,arrived)
#         ΣV = delete_exc_voltage(ΣV, exc_mask)
#
#         spk = take_step(spk) + new_spikes*stepsize
#
#         push!(firing_count, n_firing)
#         push!(excited_id, exc_mask)
#         if sum(exc_mask)==0. && n_firing == 0.
#             break
#         end
#     end
#     return firing_count, excited_id
# end

function run_inference(spk; maxiters = 100)
    firing_count = []
    excited_id = []
    ΣV = zeros(size(spk,2))
    for i in 1:maxiters
        if i == 4
            @show i
        end
        n_firing = sum(spk .!= 0)

        arrived = check_arrival(spk)

        exc_mask, ΣV = synapse_integration(ΣV, W, arrived, thresh)

        new_spikes = update_spikes(spk,exc_mask)

        spk = delete_finished_spike(spk,arrived)
        ΣV = delete_exc_voltage(ΣV, exc_mask)

        spk = take_step(spk) + new_spikes*stepsize

        push!(firing_count, n_firing)
        push!(excited_id, exc_mask)
        if sum(exc_mask)==0. && n_firing == 0.
            break
        end
    end
    return firing_count, excited_id
end


function plot_results()
    p1 =  plot(ncnt)

    a = reduce(hcat,id_excited)
    a = Float64.(a)
    p2 = heatmap(a,seriescolor=:binary)

    hist = sum(a,dims=2)
    p3 = histogram(hist,bins=25)

    plot(p1, p2, layout=(1,2))
end



## loss function
function loss(id_excited)
    a = reduce(hcat,id_excited)
    a = Float64.(a)
    # sum(a[end-9:end],dims=2) ./ size(a,2)
    sum(a[end-9:end,:],dims=2) ./ size(a,2)
end
# get inference results, calculate loss

## Input handling

# transform input format into spike train

## Training loop

#
