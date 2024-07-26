"""
Arguments:
1   IPART file path
2   Show legend?
"""

using Plots, Dates
using SunsetFileIO

pyplot()

arg_node_file = ARGS[1]
arg_show_legend = tryparse(Bool, ARGS[2])

if !isfile(arg_node_file)
    println(arg_node_file)
    printstyled("arg_node_file is not a file, exiting.\n", color = :red)
    exit()
end


(arg_D, arg_n_line_skip) = ask_file_type("IPART")
arg_keep_check_f_and_args = ask_skip()
(arg_L_char, ) = ask_scale()

println("Reading IPART file")
node_set = read_IPART_file(arg_node_file, arg_D, arg_n_line_skip)
println("We have a total of ", length(node_set.set), " nodes")

scale!(node_set, arg_L_char)

node_indices = get_shuffle_keep_indices(node_set, arg_keep_check_f_and_args...)
keep_indices!(node_set, node_indices)
println("and we are drawing ", length(node_set.set), " of them")


println("getting node colours")

type_transformer(type) = type >= 0 ? type : -1

type_dict = Dict(
    999 => (:grey, "Unstructured Nodes"),
    0   => (:green, "Wall Nodes"),
    1   => (:blue, "Inflow Nodes"),
    2   => (:red, "Outflow Nodes"),
    -1  => (:orange, "Finite Difference Nodes"),
)

# Get n vectors, separating the node set into several by their type
function keep_check_type(node_set, indices, type_to_keep)
    type_values = get_field_by_name(node_set, "type")[indices]
    keep_values = [type_transformer(type) == type_to_keep for type in type_values]
    return keep_values
end

node_type_sets = NodeSet[]
for (node_type, _) in type_dict
    indices = get_shuffle_keep_indices(node_set, (keep_check_type, (node_type, )))
    node_type_set = keep_indices(node_set, indices)
    push!(node_type_sets, node_type_set)
end

println("plotting ", length(node_set.set)," nodes")

x_values = get_field_by_name(node_set, "x")
y_values = get_field_by_name(node_set, "y")
x_min = minimum(x_values)
x_max = maximum(x_values)
y_min = minimum(y_values)
y_max = maximum(y_values)
x_size = x_max - x_min
y_size = y_max - y_min
frame_margin = 0.2 * max(x_size, y_size)
x_limits = (x_min - frame_margin, x_max + frame_margin)
y_limits = (y_min - frame_margin, y_max + frame_margin)

tick_step = 0.2 * arg_L_char
round_step(x, step) = round(x / step) * step
xt1 = round_step(x_limits[1], tick_step)
yt1 = round_step(y_limits[1], tick_step)

node_plot = scatter(
    aspect_ratio = :equal, legend = arg_show_legend,
    xlimits = x_limits, ylimits = y_limits, xlabel = "\$x\$", ylabel = "\$y\$",
    size = (1000, 750),
    xticks = xt1:tick_step:x_limits[2], yticks = yt1:tick_step:y_limits[2],
    xtickfontrotation = 90.0
)
for node_type_set in node_type_sets
    if length(node_type_set.set) == 0
        continue
    end

    type_tuple = type_dict[type_transformer(get_field_by_name(node_type_set.set[1], "type"))]
    marker_colour = type_tuple[1]
    label = type_tuple[2]
    println(Symbol(marker_colour), " ", label)
    x = get_field_by_name(node_type_set, "x")
    y = get_field_by_name(node_type_set, "y")
    println(length(x))
    scatter!(
        node_plot,
        x, y,
        markercolor = marker_colour,
        markerstrokewidth = 0.2, label = label,
    )
end

if isinteractive()
    display(node_plot)

    println("press Enter to close Julia and the plot")
    readline()
    exit()
else
    savefig(node_plot, "plot-nodes_$(Dates.now()).png")
end
