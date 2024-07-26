"""
IPART
---
1   x
2   y
3   node type
4   n.x
5   n.y
6   s

nodes
---
1   x
2   y
3   s
4   h
5   node type

fields
---
1   rho
2   u
3   v
4   vort
5   T
6   p
7   hrr
8   Y1
9   Y2
10  etc.

flame
---
1   x
2   y
3   u
4   v
5   vort
6   rho
7   rhoE
8   T
9   p
10  Y1
11  Y2 
12  etc
"""
module ReadFiles

export
    FieldValue,
    Field,
    axes_strings,
    v_string,
    n_string,
    Y_string,
    position_fields,
    v_fields,
    nodes_fields,
    fields_fields,
    IPART_fields,
    flame_fields,

    Node,
    NodeSet,
    stitch_node_sets,
    join_node_sets,
    check_field,
    check_position,
    get_field_index,
    get_field_by_name,
    zip,
    get_positions,
    set_field_by_name!,
    set_positions!,
    add_field!,
    add_dimension!,
    copy_node_set,
    reflect!,
    scale!,
    translate!,
    check_node_skip_stride,
    check_node_skip_box,
    skip_indices!,
    shuffle_skip!,

    read_nodes_files,
    read_fields_files,
    read_IPART_files,
    read_flame_files,
    read_nodes_and_fields_files,
    ask_file_type,
    ask_skip,
    ask_scale


using Random

include("fields.jl")
include("node_sets.jl")
include("read_files.jl")


end