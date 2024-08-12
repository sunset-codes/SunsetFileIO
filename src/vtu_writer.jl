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




function reduce_types(old_type :: Type)
    if old_type == Float64
        return Float32
    elseif old_type == Int64
        return Int32
    end
    return old_type
end

function group_names(node_set, names)
    grouped_names = Any[]
    for field_name_group in [axes_strings, v_strings, n_strings]
        if !all([!check_field(node_set, field_name) for field_name in field_name_group])      # If we have any of this data, add those fields
            push!(grouped_names, filter(name -> name in field_name_group, names))
            filter!(name -> !(name in field_name_group), names)
        end
    end
    push!(grouped_names, [[name] for name in names]...)
end

nice_field_titles = Dict(
    [axis_string => axis_string for axis_string in axes_strings]...,
    [v_string => v_string for v_string in v_strings]...,
    [n_string => n_string for n_string in n_strings]...,
    "s" => "Node Spacing",
    "h" => "Stencil Size",
    "type" => "Node Type",
    "rho" => "Density",
    "vort" => "Vorticity Scalar",
    "T" => "Temperature",
    "p" => "Pressure",
    "hrr" => "Heat Release Rate",
    "proc" => "Processor",
)

function get_nice_field_title(field_name :: String)
    if field_name ∉ keys(nice_field_titles)
        return field_name
    end
    return nice_field_titles[field_name]
end

function get_nice_field_title(names)
    names_title = get_nice_field_title(names[1])
    if length(names) > 1
        if names[1] in axes_strings
            names_title = "Coordinate"
        elseif names[1] in v_strings
            names_title = "Velocity"
        elseif names[1] in v_strings
            names_title = "Boundary Normal"
        else
            names_title = string("(", join(get_nice_field_title.(names), ", "), ")")
        end
    end
    return names_title
end

function write_vtu_data_array(out_file, type :: T, name, data_array) where { T <: Union{AbstractString, Type} }
    write(out_file, vtu_start_data_array(type, name; n_components = 1))
    for datum in data_array                          # Only write those nodes which have been included
        write(out_file, string(datum))                     # Having no whitespace saves up to ~60% on storage space
        write(out_file, "\n")
    end
    write(out_file, vtu_end_data_array)
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


function open_and_write_vtu(out_file_path, node_set, D)
    coords_vecs = [get_field_by_name(node_set, axis_string) for axis_string in axes_strings[1:D]]
    coords = [coords_vecs[i][j] for i in axes(coords_vecs, 1), j in axes(coords_vecs[1], 1)]

    connectivity = 1:length(node_set.set) |> collect
    cells = [MeshCell(VTKCellTypes.VTK_VERTEX, [con]) for con in connectivity]

    # vtk_grid(
    #     out_file_path,
    #     coords,
    #     cells;
    #     ascii = true,
    #     append = false
    # ) do vtu_file
    #     names = [field.name for field in node_set.set[1].fields]
    #     grouped_names = group_names(node_set, names)
    #     for names in grouped_names
    #         is_fields = [get_field_index(node_set, name) for name in names]
    #         old_types = [node_set.set[1].fields[i_field].type for i_field in is_fields]
    #         new_types = [reduce_types(old_type) for old_type in old_types]

    #         fields_data_vecs = [get_field_by_name(node_set, name) for name in names]
    #         fields_data = [new_types[i](fields_data_vecs[i][j]) for i in axes(fields_data_vecs, 1), j in axes(fields_data_vecs[1], 1)]

    #         vtu_file[get_nice_field_title(names)] = fields_data
    #     end
    # end

    open(out_file_path, "w") do out_file
        ## Beginning stuff
        write(out_file, vtu_start)
        write(out_file, vtu_start_piece(length(new_node_set.set)))
        
        ## Main stuff
        # Points
        write(out_file, vtu_start_points)

        write_vtu_data_array(out_file, node_set, false, axes_strings[1:3]...)
    
        write(out_file, vtu_end_points)
    
        # Point data
        write(out_file, vtu_start_point_data)

        names = [field.name for field in node_set.set[1].fields]
        grouped_names = group_names(node_set, names)
        for names in grouped_names
            write_vtu_data_array(out_file, node_set, true, names...)
        end
    
        write(out_file, vtu_end_point_data)
    
        # Cells
        write(out_file, vtu_start_cells)

        write_vtu_data_array(out_file, "Int32", "connectivity", [i_node - 1 for i_node in axes(node_set.set, 1)])
        write_vtu_data_array(out_file, "Int32", "offsets", [i_node for i_node in axes(node_set.set, 1)])
        write_vtu_data_array(out_file, "Int32", "types", [1 for i_node in axes(node_set.set, 1)])
    
        write(out_file, vtu_end_cells)    
        
        ## End stuff
        write(out_file, vtu_end_piece)
        write(out_file, vtu_end)
    end


    return nothing
end