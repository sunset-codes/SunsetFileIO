### READ FILES

nodes_file_path(data_out_path, i_core) = joinpath(data_out_path, string("nodes_", 10000 + i_core))
fields_file_path(data_out_path, i_core, i_frame) = joinpath(data_out_path, string("fields_", 10000 + i_core, "_", i_frame))
flame_file_path(data_out_path, i_core, i_frame) = joinpath(data_out_path, string("flame", 10000 + i_core, "_", i_frame))

function read_file(file_path, fields_array, n_line_skip)
    set = Node[]
    new_fields_array = deepcopy(fields_array)
    open(file_path, "r") do in_file
        for (i_line, line) in enumerate(eachline(in_file))
            if i_line <= n_line_skip
                continue
            end
            ft = [field.type for field in new_fields_array]
            sl = split(line)
            if length(ft) != length(sl)
                throw(ArgumentError(join(string.([new_fields_array, file_path, n_line_skip, i_line, ft, sl]), " \t")))
            end
            line_vals = parse.([field.type for field in new_fields_array], split(line))
            new_node = Node(deepcopy(new_fields_array), line_vals)
            push!(set, new_node)
        end
    end
    return NodeSet(set)
end

function read_nodes_files(data_out_path, D, n_cores)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(nodes_file_path(data_out_path, i_core), nodes_fields(D), 1)
        add_field!(new_node_set, proc_field, [i_core for _ in new_node_set.set])
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end

function read_fields_files(data_out_path, D, Y, n_cores, i_frame)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(fields_file_path(data_out_path, i_core, i_frame), fields_fields(D, Y), 5)
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end

function read_IPART_file(file_path, D, n_line_skip)
    node_set = read_file(file_path, IPART_fields(D), n_line_skip)
    # Add in the nodes which are missing
    fd_set = Node[]
    x = get_field_by_name(node_set, "x")
    y = get_field_by_name(node_set, "y")
    type = get_field_by_name(node_set, "type")
    n_x = get_field_by_name(node_set, "n_x")
    n_y = get_field_by_name(node_set, "n_y")
    s = get_field_by_name(node_set, "s")
    indices = findall(t_val -> t_val < 999 && t_val > -1, type)
    for i_node in indices
        push!(fd_set, Node(IPART_fields(2), [x[i_node] + 1 * s[i_node] * n_x[i_node], y[i_node] + 1 * s[i_node] * n_y[i_node], -1, 0.0, 0.0, s[i_node]]))
        push!(fd_set, Node(IPART_fields(2), [x[i_node] + 2 * s[i_node] * n_x[i_node], y[i_node] + 1 * s[i_node] * n_y[i_node], -2, 0.0, 0.0, s[i_node]]))
        push!(fd_set, Node(IPART_fields(2), [x[i_node] + 3 * s[i_node] * n_x[i_node], y[i_node] + 1 * s[i_node] * n_y[i_node], -3, 0.0, 0.0, s[i_node]]))
        push!(fd_set, Node(IPART_fields(2), [x[i_node] + 4 * s[i_node] * n_x[i_node], y[i_node] + 1 * s[i_node] * n_y[i_node], -4, 0.0, 0.0, s[i_node]]))
    end
    return join_node_sets(NodeSet(fd_set), node_set)
end

function read_flame_files(data_out_path, D, Y, n_cores, i_frame)
    node_sets = NodeSet[]
    for i_core in 0:(n_cores - 1)
        new_node_set = read_file(flame_file_path(data_out_path, i_core, i_frame), flame_fields(D, Y), 0)
        push!(node_sets, new_node_set)
    end
    return join_node_sets(node_sets...)
end



function read_nodes_and_fields_files(data_out_path, D, Y, n_cores, i_frame)
    node_set = read_nodes_files(data_out_path, D, n_cores)
    fields_set = read_fields_files(data_out_path, D, Y, n_cores, i_frame)
    return stitch_node_sets(node_set, fields_set)
end

function read_nodes_and_fields_files(node_files_set, data_out_path, D, Y, n_cores, i_frame)
    fields_set = read_fields_files(data_out_path, D, Y, n_cores, i_frame)
    return stitch_node_sets(node_files_set, fields_set)
end






function ask_D()
    printstyled("Dimension\n", color = :blue)
    temp_str = readline()
    return parse(Int64, temp_str)
end
function ask_Y()
    printstyled("Number of species\n", color = :blue)
    temp_str = readline()
    return parse(Int64, temp_str)
end
function ask_n_cores()
    printstyled("Number of cores used\n", color = :blue)
    temp_str = readline()
    return parse(Int64, temp_str)
end
function ask_i_frame()
    printstyled("Output frame number\n", color = :blue)
    temp_str = readline()
    return parse(Int64, temp_str)
end
function ask_frames()
    printstyled("First frame #\n", color = :blue)
    temp_str = readline()
    arg_frame_start = parse(Int64, temp_str)

    printstyled("Final frame #\n", color = :blue)
    temp_str = readline()
    arg_frame_end = parse(Int64, temp_str)

    return (arg_frame_start, arg_frame_end)
end
function ask_n_line_skip()
    printstyled("Number of lines to skip at the start of the file\n", color = :blue)
    temp_str = readline()
    return parse(Int64, temp_str)
end

function ask_file_type(file_type)
    ft_args = Any[]

    if !isinteractive()
        throw(ErrorException("Must be run in interactive mode"))
    end

    if file_type == "nodes"
        arg_D = ask_D()
        arg_n_cores = ask_n_cores()
        ft_args = [arg_D, arg_n_cores]
    elseif file_type == "fields"
        arg_D = ask_D()
        arg_Y = ask_Y()
        arg_n_cores = ask_n_cores()
        arg_i_frame = ask_i_frame()
        ft_args = [arg_D, arg_Y, arg_n_cores, arg_i_frame]
    elseif file_type == "many fields"
        arg_D = ask_D()
        arg_Y = ask_Y()
        arg_n_cores = ask_n_cores()
        arg_frames = ask_frames()
        ft_args = [arg_D, arg_Y, arg_n_cores, arg_frames]
    elseif file_type == "flame"
        arg_D = ask_D()
        arg_Y = ask_Y()
        arg_n_cores = ask_n_cores()
        arg_i_frame = ask_i_frame()
        ft_args = [arg_D, arg_Y, arg_n_cores, arg_i_frame]
    elseif file_type == "many flames"
        arg_D = ask_D()
        arg_Y = ask_Y()
        arg_n_cores = ask_n_cores()
        arg_frames = ask_frames()
        ft_args = [arg_D, arg_Y, arg_n_cores, arg_frames]
    elseif file_type == "IPART"
        arg_D = ask_D()
        arg_n_line_skip = ask_n_line_skip()
        ft_args = [arg_D, arg_n_line_skip]
    else
        throw(ArgumentError("File type not accepted"))
    end

    return ft_args
end

function ask_file_type()
    printstyled("What sort of file type do you want to input\n", color = :blue)
    arg_file_type = readline()

    return ask_file_type(arg_file_type)
end

function ask_skip()
    keep_check_f_and_args = Vector{Any}[]

    if !isinteractive()
        throw(ErrorException("Must be run in interactive mode"))
    end

    printstyled("Skip nodes?\n", color = :blue)
    temp_str = readline()
    arg_do_skip = parse(Bool, temp_str)
    
    if !arg_do_skip
        return keep_check_f_and_args
    end

    printstyled("Constant node spacing?\n", color = :blue)
    temp_str = readline()
    arg_do_boxing = parse(Bool, temp_str)
    
    if arg_do_boxing
        printstyled("New spacing\n", color = :blue)
        temp_str = readline()
        arg_box_size = parse(Float64, temp_str)
        push!(keep_check_f_and_args, [keep_check_box, (arg_box_size, )])
    end
    
    printstyled("Stride?\n", color = :blue)
    temp_str = readline()
    arg_do_stride = parse(Bool, temp_str)
    
    if arg_do_stride
        printstyled("Use 1/# of the nodes\n", color = :blue)
        temp_str = readline()
        arg_stride_n = parse(Int64, temp_str)
        push!(keep_check_f_and_args, [skip_check_stride, (arg_stride_n, )])
    end
    
    printstyled("Enforce a maximum number of nodes?\n", color = :blue)
    temp_str = readline()
    arg_do_max_nodes = parse(Bool, temp_str)

    if arg_do_max_nodes
        printstyled("Maximum # of nodes\n", color = :blue)
        temp_str = readline()
        arg_max_nodes = parse(Int64, temp_str)
        push!(keep_check_f_and_args, [keep_check_max, (arg_max_nodes, )])
    end

    return keep_check_f_and_args
end

function ask_scale()
    if !isinteractive()
        throw(ErrorException("Must be run in interactive mode"))
    end

    printstyled("Scale down x, y, s and h by this # (L_char, 1 for no scaling)\n", color = :blue)
    temp_str = readline()
    arg_scale = parse(Float64, temp_str)

    return arg_scale
end
