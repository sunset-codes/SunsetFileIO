"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'

ARGS
---
1   data_out directory path
2   Output directory
"""

using Dates, Printf, Random

using SunsetFileIO


arg_data_dir = ARGS[1]
arg_out_dir = ARGS[2]

if !isdir(arg_data_dir)
    println(arg_data_dir)
    printstyled("arg_data_dir is not a directory, exiting.\n", color = :red)
    exit()
elseif !isdir(arg_out_dir)
    println(arg_out_dir)
    printstyled("arg_out_dir is not a directory, exiting.\n", color = :red)
    exit()
end

(arg_D, arg_Y, arg_n_cores, (arg_frame_start, arg_frame_end)) = ask_file_type("many fields")
arg_keep_check_f_and_args = ask_skip()
(arg_L_char, ) = ask_scale()
(arg_do_reflect, arg_reflect_p1, arg_reflect_p2) = ask_reflect()

println("Reading nodes files")
node_set = read_nodes_files(arg_data_dir, arg_D, arg_n_cores)
println("We have a total of ", length(node_set.set), " nodes")

scale!(node_set, arg_L_char)

node_indices = get_shuffle_keep_indices(node_set, arg_keep_check_f_and_args...)
println("and we are writing ", length(node_set.set), " of them")

if arg_do_reflect
    node_set_reflected = copy_node_set(node_set)
    reflect!(node_set_reflected, arg_reflect_p1, arg_reflect_p2)
    node_set = join_node_sets(node_set, node_set_reflected)
end


for i_frame in arg_frame_start:arg_frame_end
    field_set = read_fields_files(arg_data_dir, arg_D, arg_Y, arg_n_cores, i_frame)
    keep_indices!(field_set, node_indices)

    if arg_do_reflect
        field_set_reflected = copy_node_set(field_set)
        field_set = join_node_sets(field_set, field_set_reflected)    
    end

    full_set = stitch_node_sets(node_set, field_set)

    # Output to vtu file
    out_file_name = @sprintf "%04i" i_frame - 1
    out_file_name = string("ben_new_LAYER", out_file_name, ".vtu")
    out_file_path = joinpath(arg_out_dir, out_file_name)
    println("Writing nodes to ", out_file_path)
    open_and_write_vtu(out_file_path, full_set, arg_D)
end

exit()