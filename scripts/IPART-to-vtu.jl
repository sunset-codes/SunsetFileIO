"""
Creates .vtu files out of IPART files. Output files are named 'IPART.<date_time>.vtu'

ARGS
---
1   IPART file path
"""

using Dates
using SunsetFileIO


arg_node_file = ARGS[1]

if !isfile(arg_node_file)
    println(arg_node_file)
    printstyled("arg_node_file is not a file, exiting.\n", color = :red)
    exit()
end

(arg_D, arg_n_line_skip) = ask_file_type("IPART")
arg_keep_check_f_and_args = ask_skip()
(arg_L_char, ) = ask_scale()

println("Reading nodes files")
node_set = read_IPART_file(arg_node_file, arg_D, arg_n_line_skip)
println("We have a total of ", length(node_set.set), " nodes")

# Scale down nodes
scale!(node_set, arg_L_char)

node_indices = get_shuffle_keep_indices(node_set, arg_keep_check_f_and_args...)
keep_indices!(node_set, node_indices)
println("and we are writing ", length(node_set.set), " of them")


out_file_path = joinpath(dirname(arg_node_file), "IPART.$(Dates.now()).vtu")
println("Writing to ", out_file_path)

open_and_write_vtu(out_file_path, node_set, arg_D)

exit()