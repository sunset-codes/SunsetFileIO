### NODE SETS

struct Node
    fields :: Vector{Field}
    values :: Vector{FieldValue}
end

function check_field(node :: Node, field_name)
    names = [field.name for field in node.fields]
    return field_name ∈ names
end


function get_field_index(node :: Node, field_name)
    if !check_field(node, field_name)
        throw(ArgumentError("That field does not exist in this node set"))
    end
    first_node_names = [field.name for field in node.fields]
    i_field = findall(val -> val == field_name, first_node_names)[1]
    return i_field
end

function get_field_by_name(node :: Node, field_name)
    i_field = get_field_index(node, field_name)
    return node.values[i_field]
end


mutable struct NodeSet
    set :: Vector{Node}
end

function stitch_node_sets(node_sets...)
    # Take copies of node_sets
    node_sets_copies = [copy_node_set(node_set) for node_set in node_sets]
    if !allequal([length(node_set.set) for node_set in node_sets_copies])
        throw(ArgumentError("These node sets contain different numbers of nodes"))
    end
    # Only pick out each unique field once, prioritising values from earlier node sets
    # fields = vcat([node_set.set[1].fields for node_set in node_sets_copies]...)
    fields = Field[]
    field_node_sets_indices = Vector{Int64}[Int64[] for _ in node_sets_copies]
    for (i_node_set, node_set) in enumerate(node_sets_copies)
        node_set_fields = node_set.set[1].fields
        for (i_field, field) in enumerate(node_set_fields)
            already_included = field.name in [old_field.name for old_field in fields]
            if !already_included
                push!(fields, field)
                push!(field_node_sets_indices[i_node_set], i_field)
            end
        end
    end
    # Then stitch
    new_set = Node[
        Node(fields, vcat([
            node_set.set[i_node].values[field_node_sets_indices[i_node_set]]
            for (i_node_set, node_set) in enumerate(node_sets_copies)
        ]...))
        for i_node in axes(node_sets_copies[1].set, 1)
    ]
    return NodeSet(new_set)
end

function join_node_sets(node_sets...)
    # Take copies
    node_sets_copies = [copy_node_set(node_set) for node_set in node_sets]
    # Then join
    return NodeSet(vcat([node_set.set for node_set in node_sets_copies]...))
end

# true if has field false otherwise
function check_field(node_set :: NodeSet, field_name)
    return check_field(node_set.set[1], field_name)
end

# Returns D if position or 0 if no position
function check_position(node_set)
    axis_present = Bool[check_field(node_set, axis_string) for axis_string in axes_strings]
    return count(==(true), axis_present)
end

function get_field_index(node_set :: NodeSet, field_name)
    return get_field_index(node_set.set[1], field_name)
end

function get_field_by_name(node_set :: NodeSet, field_name)
    i_name_field = get_field_index(node_set, field_name)
    field_type = node_set.set[1].fields[i_name_field].type
    return field_type[node_set.set[i_node].values[i_name_field] for i_node in axes(node_set.set, 1)]
end

# Can zip or unzip because everything is arrays
function zip_array(a_a_f)
    a_f_a = [[a_a_f[i_field][i_node] for i_field in axes(a_a_f, 1)] for i_node in axes(a_a_f[1], 1)]
    return a_f_a
end

function get_positions(node_set)
    D = check_position(node_set)
    if D == 0
        throw(ArgumentError("This node set contains no positions"))
    end
    node_set_positions = [get_field_by_name(node_set, axes_strings[i_axis]) for i_axis in 1:D]
    zip_node_positions = zip_array(node_set_positions)
    return zip_node_positions
end

function set_field_by_name!(node_set, field_name, field_values)
    set = node_set.set
    if length(node_set.set) != length(field_values)
        throw(ArgumentError("Mismatch in number of nodes"))
    end
    i_name_field = get_field_index(node_set, field_name)
    for (i_node, node) in enumerate(set)
        node.values[i_name_field] = field_values[i_node]
    end
    return nothing
end

function set_positions!(node_set, positions_zipped)
    positions_unzipped = zip_array(positions_zipped)
    for i_axis in axes(positions_zipped[1], 1)
        set_field_by_name!(node_set, axes_strings[i_axis], positions_unzipped[i_axis])
    end
    return nothing
end

function add_field!(node_set, field, values)
    # Skip if this field is already there
    if check_field(node_set, field.name)
        printstyled("node set already contains this field\n", color = :red)
        return nothing
    end
    empty_value = zero(field.type)
    set = node_set.set
    for i_node in axes(set, 1)
        push!(set[i_node].fields, field)
        push!(set[i_node].values, empty_value)
    end
    set_field_by_name!(node_set, field.name, values)
    return nothing
end

function add_dimension!(node_set, D, desired_D)
    if D < desired_D
        for i_axis in (D + 1):desired_D
            check_field(node_set, "x")   && add_field!(node_set, Field(axes_strings[i_axis], Float64), [zero(Float64) for i_node in axes(node_set.set, 1)])
            check_field(node_set, "v_x") && add_field!(node_set, Field(v_string(i_axis), Float64), [zero(Float64) for i_node in axes(node_set.set, 1)])
            check_field(node_set, "n_x") && add_field!(node_set, Field(n_string(i_axis), Float64), [zero(Float64) for i_node in axes(node_set.set, 1)])
        end
    end
    return nothing
end

function copy_node_set(node_set)
    new_set = Node[Node(copy(node.fields), copy(node.values)) for node in node_set.set]
    return NodeSet(new_set)
end



function reflect!(node_set, p1, p2)
    D = check_position(node_set)
    if D != length(p1) || D != length(p2)
        throw(ArgumentError("Position dimensions don't match"))
    end
    node_positions = get_positions(node_set)
    for (i_node, position) in enumerate(node_positions)
        dot(x, y) = sum(x .* y)
        l_x = dot(p2 - p1, position - p1) / dot(p2 - p1, p2 - p1)
        new_position = position + 2 * (p1 + l_x * (p2 - p1) - position)
        node_positions[i_node] = new_position
    end
    set_positions!(node_set, node_positions)
    return nothing
end

# We do not allow vector arguments as stretching is not allowed for these LABFM nodes
function scale!(node_set, scale :: T) where { T <: Real }
    # Scale positions
    node_positions = get_positions(node_set)
    for (i_node, position) in enumerate(node_positions)
        node_positions[i_node] = position .* scale
    end
    set_positions!(node_set, node_positions)
    # Scaling also affects s and h if they're there
    if check_field(node_set, "s")
        s = get_field_by_name(node_set, "s")
        set_field_by_name!(node_set, "s", s .* scale)
    end
    if check_field(node_set, "h")
        h = get_field_by_name(node_set, "h")
        set_field_by_name!(node_set, "h", h .* scale)
    end
    return nothing
end

function translate!(node_set, p)
    D = check_position(node_set)
    if D != length(p)
        throw(ArgumentError("Position dimensions don't match"))
    end
    node_positions = get_positions(node_set)
    for (i_node, position) in enumerate(node_positions)
        node_positions[i_node] = position .+ p
    end
    set_positions!(node_set, node_positions)
    return nothing
end


## Skipping


function keep_check_stride(node_set, indices, stride)
    keep_nodes = [i_node % stride == 0 for i_node in indices]
    return keep_nodes
end

# Only works in 2D so far
function keep_check_box(node_set, indices, box_size)
    x = get_field_by_name(node_set, "x")
    y = get_field_by_name(node_set, "y")
    nodes_x1 = minimum(x)
    nodes_x2 = maximum(x)
    nodes_y1 = minimum(y)
    nodes_y2 = maximum(y)
    i_bin(x) = Int64(floor((x - nodes_x1) / box_size)) + 1
    j_bin(y) = Int64(floor((y - nodes_y1) / box_size)) + 1
    
    node_bins = [false for j in 1:j_bin(nodes_y2), i in 1:i_bin(nodes_x2)]
    keep_nodes = [true for i_node in indices]

    for i_node in indices
        node_i_bin = i_bin(x[i_node])
        node_j_bin = j_bin(y[i_node])
        bin_filled = node_bins[node_j_bin, node_i_bin]
        keep_nodes[i_node] = !bin_filled
        if !bin_filled
            node_bins[node_j_bin, node_i_bin] = true
        end
    end
    return keep_nodes
end

function keep_check_max(node_set, indices, max_nodes)
    keep_nodes = [count <= max_nodes for count in axes(indices, 1)]
    return keep_nodes
end

function keep_indices(node_set, indices)
    new_node_set = copy_node_set(node_set)
    return NodeSet(new_node_set.set[indices])
end

function keep_indices!(node_set, indices)
    node_set.set = node_set.set[indices]
    return nothing
end

"""
keep_check_f_and_args are
- A 'check_node_skip' function
- A tuple of arguments to that function which will get splatted in
"""
function get_shuffle_keep_indices(node_set, keep_check_f_and_args...)
    indices_shuffled = shuffle(axes(node_set.set, 1))
    
    for (keep_check_f, keep_check_args) in keep_check_f_and_args
        keep_check = keep_check_f(node_set, indices_shuffled, keep_check_args...)
        indices_shuffled = indices_shuffled[findall(keep_check)]
    end

    return sort(indices_shuffled)
end



