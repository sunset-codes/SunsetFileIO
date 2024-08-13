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
module SunsetFileIO

export
    FieldValue,
    Field,
    axes_strings,
    v_strings,
    n_strings,
    Y_string,
    position_fields,
    s_field,
    h_field,
    type_field,
    n_fields,
    rho_field,
    v_fields,
    vort_field,
    T_field,
    p_field,
    hrr_field,
    Y_fields,
    rhoE_field,
    proc_field,
    nodes_fields,
    fields_fields,
    IPART_fields,
    flame_fields,

    NodeSet,
    stitch_node_sets,
    join_node_sets,
    check_field,
    check_position,
    get_field_index,
    get_field_by_name,
    zip_array,
    get_positions,
    set_field_by_name!,
    set_positions!,
    add_field!,
    copy_node_set,

    reflect_origin!,
    reflect!,
    scale!,
    translate!,

    keep_check_stride,
    keep_check_box,
    keep_check_max,keep_indices,
    keep_indices,
    keep_indices!,
    get_shuffle_keep_indices,

    read_nodes_files,
    read_fields_files,
    read_IPART_file,
    read_flames_file,
    read_vtu_file,
    read_nodes_and_fields_files,

    ask_file_type,
    ask_skip,
    ask_scale,
    ask_reflect,

    open_and_write_vtu


using Random, Dates, WriteVTK, ReadVTK, DelimitedFiles

include("fields.jl")
include("node_sets.jl")
include("transform.jl")
include("skip.jl")
include("read_files.jl")
include("ask.jl")
include("vtu_writer.jl")


end