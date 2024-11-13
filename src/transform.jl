dot(x, y) = sum(x .* y)



function translate!(vectors, p)
    vectors .= [vector + p for vector in vectors]
    return nothing
end    

"""
Reflect the vectors contained in vectors on the line 0 to p
"""
function reflect_origin!(vectors :: T, p) where { T <: AbstractVector }
    for (i_node, v) in enumerate(vectors)
        l_v = dot(p, v) / dot(p, p)
        v_new = 2 * (l_v * p) - v
        vectors[i_node] = v_new
    end
    return nothing
end

function scale!(vectors :: T, scaling) where { T <: AbstractVector }
    vectors .*= scaling
    return nothing
end

function reflect!(node_set :: NodeSet, p1, p2)
    if length(p2) != length(p1)
        throw(ArgumentError("Position dimensions don't match"))
    end
    # Reflect every vector field
    for (vector_field_name, _) in filter(vector_field_scalar_fields -> check_vector_field(node_set, vector_field_scalar_fields.first) != 0, vector_fields_scalars)
        vectors = get_vector_by_name(node_set, vector_field_name)
        vector_field_name == "position" && translate!(vectors, -p1)
        reflect_origin!(vectors, p2 - p1)
        vector_field_name == "position" && translate!(vectors, p1)
        set_vector_field_by_name!(node_set, vector_field_name, vectors)
    end
    # Invert Vorticity for 2D flows
    check_field(node_set, "vort") && set_field_by_name!(node_set, "vort", -get_field_by_name(node_set, "vort"))
    return nothing
end

# We do not allow vector arguments as stretching is not allowed for these LABFM nodes
function scale!(node_set :: NodeSet, scaling)
    # Scale positions
    node_positions = get_positions(node_set)
    scale!(node_positions, scaling)
    set_positions!(node_set, node_positions)
    # Scaling also affects s and h if they're there
    check_field(node_set, "s") && set_field_by_name!(node_set, "s", get_field_by_name(node_set, "s") .* scaling)
    check_field(node_set, "h") && set_field_by_name!(node_set, "h", get_field_by_name(node_set, "h") .* scaling)
    D = check_position(node_set)
    check_field(node_set, "vol") && set_field_by_name!(node_set, "vol", get_field_by_name(node_set, "vol") .* scaling^D)
    return nothing
end

function translate!(node_set :: NodeSet, p)
    node_positions = get_positions(node_set)
    translate!(node_positions, p)
    set_positions!(node_set, node_positions)
    return nothing
end


