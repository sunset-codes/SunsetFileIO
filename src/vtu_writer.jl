vtu_start = """
<?xml version="1.0"?>

<VTKFile type= "UnstructuredGrid"  version= "0.1"  byte_order= "BigEndian">
  <UnstructuredGrid>
"""
vtu_end = """
  </UnstructuredGrid>
</VTKFile>
"""
vtu_start_piece(n_nodes) = """
    <Piece NumberOfPoints="$n_nodes" NumberOfCells="$n_nodes">
"""
vtu_end_piece = """
    </Piece>
"""
vtu_start_points = """
      <Points>
"""
vtu_end_points = """
      </Points>
"""
vtu_start_point_data = """
      <PointData>
"""
vtu_end_point_data = """
      </PointData>
"""
vtu_start_data_array(type, name; n_components = 1) = """
        <DataArray type="$type" $(name == "" ? "" : "Name=\"$name\" ")$(n_components == 1 ? "" : string("NumberOfComponents=\"", n_components, "\" "))format="ascii">
"""

vtu_end_data_array = """
        </DataArray>
"""
vtu_start_cells = """
      <Cells>
"""
vtu_end_cells = """
      </Cells>
      <CellData>
      </CellData>
"""

function write_vtu_data_array(out_file, type :: T, name, data_array) where { T <: Union{AbstractString, Type} }
    write(out_file, vtu_start_data_array(type, name; n_components = 1))
    for datum in data_array                          # Only write those nodes which have been included
        write(out_file, string(datum))                     # Having no whitespace saves up to ~60% on storage space
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
end

function reduce_types(old_type :: Type)
    if old_type == Float64
        return Float32
    elseif old_type == Int64
        return Int32
    end
    return old_type
end

function write_vtu_data_array(out_file, node_set, use_name :: Bool, field_names...)
    field_indices = [get_field_index(node_set, field_name) for field_name in field_names]
    old_type = node_set.set[1].fields[field_indices[1]].type
    new_type = reduce_types(old_type)
    
    write(out_file, vtu_start_data_array(new_type, use_name ? join(field_names, " ") : ""; n_components = length(field_names)))
    
    zipped_values = zip_array([get_field_by_name(node_set, field_name) for field_name in field_names])
    for node_values in zipped_values
        write(out_file, string(join(new_type.(node_values), " \t")))    # Having no whitespace saves up to ~60% on storage space
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
end

function group_names(node_set, names)
    grouped_names = Any[]
    if check_field(node_set, "x")  
        push!(grouped_names, filter(name -> name in axes_strings[1:3], names))
        filter!(name -> !(name in axes_strings[1:3]), names)
    end
    if check_field(node_set, "v_x")
        push!(grouped_names, filter(name -> name in v_string.(1:3), names))
        filter!(name -> !(name in v_string.(1:3)), names)
    end
    if check_field(node_set, "n_x")
        push!(grouped_names, filter(name -> name in n_string.(1:3), names))
        filter!(name -> !(name in n_string.(1:3)), names)
    end
    push!(grouped_names, [[name] for name in names]...)
end

function write_vtu_point_data(out_file, node_set)
    write(out_file, vtu_start_point_data)

    names = [field.name for field in node_set.set[1].fields]
    grouped_names = group_names(node_set, names)
    for names in grouped_names
        write_vtu_data_array(out_file, node_set, true, names...)
    end

    write(out_file, vtu_end_point_data)
end

function write_vtu_points(out_file, node_set)
    write(out_file, vtu_start_points)

    write_vtu_data_array(out_file, node_set, false, axes_strings[1:3]...)

    write(out_file, vtu_end_points)
end

function write_vtu_cells(out_file, node_set)
    write(out_file, vtu_start_cells)

    write_vtu_data_array(out_file, "Int32", "connectivity", [i_node - 1 for i_node in axes(node_set.set, 1)])
    write_vtu_data_array(out_file, "Int32", "offsets", [i_node for i_node in axes(node_set.set, 1)])
    write_vtu_data_array(out_file, "Int32", "types", [1 for i_node in axes(node_set.set, 1)])

    write(out_file, vtu_end_cells)
end
  
function write_vtu(out_file, node_set, D)
    new_node_set = copy_node_set(node_set)
    add_dimension!(new_node_set, D, 3)

    # Beginning stuff
    write(out_file, vtu_start)
    write(out_file, vtu_start_piece(length(new_node_set.set)))
    
    # Main stuff
    write_vtu_points(out_file, new_node_set)
    write_vtu_point_data(out_file, new_node_set)
    write_vtu_cells(out_file, new_node_set)
    
    # End stuff
    write(out_file, vtu_end_piece)
    write(out_file, vtu_end)
end

function open_and_write_vtu(out_file_path, node_set, D)
    open(out_file_path, "w") do out_file
        write_vtu(out_file, node_set, D)
    end
end