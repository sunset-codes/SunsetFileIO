"""
For each node i_node, find the nodes which neighbour it and store them in a list
connected to the original node by a dictionary.

Could add this dictionary to node_set somehow?
"""
function calculate_node_linkage(node_set; add_to_node_set = true)
    D = check_position(node_set)
    if D == 0
        throw(ArgumentError("No position fields"))
    elseif D != 2
        throw(ArgumentError("Only implemented for 2D node sets"))
    end
    if !check_field(node_set, "h")
        throw(ArgumentError("No h field"))
    end

    x = node_set["x"]
    y = node_set["y"]
    h = node_set["h"]

    node_linkage = Array{Int64}[]
    @showprogress "Linking nodes..." for i_node in 1:length(node_set)
    # for i_node in 1:length(node_set)
        x_i = x[i_node]
        y_i = y[i_node]
        h_i = h[i_node]

        j_nodes = 1:length(node_set) |> collect
        filter!(j_node -> abs(x_i - x[j_node]) < 2h_i, j_nodes)
        filter!(j_node -> abs(y_i - y[j_node]) < 2h_i, j_nodes)

        node_linkage_i = Int64[]
        for j_node in j_nodes
            r² = (x_i - x[j_node])^2 + (y_i - y[j_node])^2
            if r² < (2h_i)^2
                push!(node_linkage_i, j_node)
            end
        end
        push!(node_linkage, node_linkage_i)
    end

    if add_to_node_set
        add_field!(node_set, node_linkage_field, node_linkage)
    end

    return node_linkage
end

"""
Uses a simple SPH calculation to get the local volumes at a node.

This is the same way the sunset codes calculate their volumes.
"""
function add_volumes!(node_set)
    D = check_position(node_set)
    if D == 0
        throw(ArgumentError("No position fields"))
    elseif D != 2
        throw(ArgumentError("Only implemented for 2D node sets"))
    end
    if !check_field(node_set, "s")
        throw(ArgumentError("No s field"))
    end
    if !check_field(node_set, "h")
        throw(ArgumentError("No h field"))
    end

    x = node_set["x"]
    y = node_set["y"]
    s = node_set["s"]
    h = node_set["h"]
    type = node_set["type"]

    node_linkage = calculate_node_linkage(node_set)

    vol_values = Vector{Float64}(undef, length(node_set))
    for i_node in 1:length(node_set)
        if type[i_node] == 999  # Non-boundary nodes
            j_nodes = node_linkage[i_node]
            vol = 0.0
            h² = h[i_node]^2
            for j_node in j_nodes
                r² = (x[i_node] - x[j_node])^2 + (y[i_node] - y[j_node])^2
                vol += (9.0 / pi) * exp(-9.0 * r² / h²) / h²
            end
            vol = 1 / vol
            vol_values[i_node] = vol
        else                    # Boundary nodes
            vol = s[i_node]^2
            vol_values[i_node] = vol
        end
    end
    add_field!(node_set, vol_field, vol_values)
    return nothing
end
