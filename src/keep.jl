
function keep_check_stride(node_set, indices, stride)
    keep_nodes = [i_node % stride == 0 for i_node in indices]
    return keep_nodes
end

# Only works in 2D so far
function keep_check_box(node_set, indices, box_size)
    x = get_field_by_name(node_set, "x")
    y = get_field_by_name(node_set, "y")
    nodes_x1 = minimum(x)
    nodes_x2 = maximum(x)
    nodes_y1 = minimum(y)
    nodes_y2 = maximum(y)
    i_bin(x) = Int64(floor((x - nodes_x1) / box_size)) + 1
    j_bin(y) = Int64(floor((y - nodes_y1) / box_size)) + 1
    
    node_bins = [false for j in 1:j_bin(nodes_y2), i in 1:i_bin(nodes_x2)]
    keep_nodes = [true for i_node in indices]

    for i_node in indices
        node_i_bin = i_bin(x[i_node])
        node_j_bin = j_bin(y[i_node])
        bin_filled = node_bins[node_j_bin, node_i_bin]
        keep_nodes[i_node] = !bin_filled
        if !bin_filled
            node_bins[node_j_bin, node_i_bin] = true
        end
    end
    return keep_nodes
end

function keep_check_max(node_set, indices, max_nodes)
    keep_nodes = [count <= max_nodes for count in axes(indices, 1)]
    return keep_nodes
end

function keep_indices(node_set, indices)
    new_node_set = copy_node_set(node_set)
    return NodeSet(node_set.fields, new_node_set.set[indices, :])
end

function keep_indices!(node_set, indices)
    node_set.set = node_set.set[indices, :]
    return nothing
end

"""
keep_check_f_and_args are
- A 'check_node_skip' function
- A tuple of arguments to that function which will get splatted in
"""
function get_shuffle_keep_indices(node_set, keep_check_f_and_args...)
    indices_shuffled = axes(node_set.set, 1)#shuffle(axes(node_set.set, 1))
    
    for (keep_check_f, keep_check_args) in keep_check_f_and_args
        keep_check = keep_check_f(node_set, indices_shuffled, keep_check_args...)
        indices_shuffled = indices_shuffled[findall(keep_check)]
    end

    return indices_shuffled#sort(indices_shuffled)
end



