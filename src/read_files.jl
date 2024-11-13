nodes_file_path(data_out_path, i_core) = joinpath(data_out_path, string("nodes_", 10000 + i_core))
fields_file_path(data_out_path, i_core, i_frame) = joinpath(data_out_path, string("fields_", 10000 + i_core, "_", i_frame))
flame_file_path(data_out_path, i_core, i_frame) = joinpath(data_out_path, string("flame", 10000 + i_core, "_", i_frame))

function read_file(file_path, fields_array, n_line_skip)
    new_fields_array = deepcopy(fields_array)
    new_set = readdlm(file_path, Any; skipstart = n_line_skip, comments = true, comment_char = '#') # This comment_char could change to '!'?
    return NodeSet(new_fields_array, new_set)
end

function read_nodes_files(data_out_path, D, n_cores)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(nodes_file_path(data_out_path, i_core), nodes_fields(D), 1)
        add_field!(new_node_set, proc_field, [i_core for _ in 1:length(new_node_set)])
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end

function read_fields_files(data_out_path, D, Y, n_cores, i_frame; has_ω = false)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(fields_file_path(data_out_path, i_core, i_frame), fields_fields(D, Y; has_ω = has_ω), 5)
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end

function read_IPART_file(file_path, D, n_line_skip)
    node_set = read_file(file_path, IPART_fields(D), n_line_skip)
    # Add in the nodes which are missing
    x = get_field_by_name(node_set, "x")
    y = get_field_by_name(node_set, "y")
    type = get_field_by_name(node_set, "type")
    n_x = get_field_by_name(node_set, "n_x")
    n_y = get_field_by_name(node_set, "n_y")
    s = get_field_by_name(node_set, "s")
    indices = findall(t_val -> t_val < 999 && t_val > -1, type)
    for i_node in indices
        new_fd_set = FieldValue[
            x[i_node] + 1 * s[i_node] * n_x[i_node]    y[i_node] + 1 * s[i_node] * n_y[i_node]    -1    0.0    0.0    s[i_node];
            x[i_node] + 2 * s[i_node] * n_x[i_node]    y[i_node] + 2 * s[i_node] * n_y[i_node]    -2    0.0    0.0    s[i_node];
            x[i_node] + 3 * s[i_node] * n_x[i_node]    y[i_node] + 3 * s[i_node] * n_y[i_node]    -3    0.0    0.0    s[i_node];
            x[i_node] + 4 * s[i_node] * n_x[i_node]    y[i_node] + 4 * s[i_node] * n_y[i_node]    -4    0.0    0.0    s[i_node];
        ]
        node_set = join_node_sets(node_set, NodeSet(IPART_fields(2), new_fd_set))
    end
    return node_set
end

function read_flames_file(data_out_path, D, Y, n_cores, i_frame)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(flame_file_path(data_out_path, i_core, i_frame), flame_fields(D, Y), 0)
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end


function read_vtu_file()

end




function read_nodes_and_fields_files(data_out_path, D, Y, n_cores, i_frame; has_ω = false)
    node_set = read_nodes_files(data_out_path, D, n_cores)
    fields_set = read_fields_files(data_out_path, D, Y, n_cores, i_frame; has_ω = has_ω)
    return stitch_node_sets(node_set, fields_set)
end

function read_nodes_and_fields_files(node_files_set, data_out_path, D, Y, n_cores, i_frame; has_ω = false)
    fields_set = read_fields_files(data_out_path, D, Y, n_cores, i_frame; has_ω = has_ω)
    return stitch_node_sets(node_files_set, fields_set)
end




