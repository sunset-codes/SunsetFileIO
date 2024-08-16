# struct Node
#     fields :: Vector{Field}
#     values :: Vector{FieldValue}
# end


## INDEXING

function Base.firstindex(node_set :: NodeSet)
    return 1
end

function Base.lastindex(node_set :: NodeSet)
    return length(node_set)
end


function Base.getindex(node_set :: NodeSet, i_nodes :: T) where T <: Union{Int64, AbstractVector{Int64}}
    return NodeSet(node_set.fields, reshape(node_set.set[i_nodes, :], (length(i_nodes), length(node_set.fields))))
end

""" Ignore for now """
function Base.setindex!(node_set :: NodeSet, node_values, i_nodes :: T) where T <: Union{Int64, AbstractVector{Int64}}
    printstyled("Cannot setindex! on a NodeSet", color = :red)
    return nothing
end

function Base.getindex(node_set :: NodeSet, field_name :: String)
    field_arr = get_field_by_name(node_set, field_name)
    return field_arr
end

function Base.setindex!(node_set :: NodeSet, field_values, field_name :: String)
    if check_field(node_set, field_name)
        set_field_by_name!(node_set, field_name, field_values)
    else
        printstyled("Field doesn't yet exist in node set, adding field.", color = :red)
        add_field!(node_set, Field(field_name, FieldValue))
    end
    return nothing
end

function Base.getindex(node_set :: NodeSet, i_node :: Int64, field_name :: String)
    return node_set[field_name][i_node]
end

function Base.setindex!(node_set :: NodeSet, node_field_value, i_node :: Int64, field_name :: String)
    i_field = get_field_index(node_set, field_name)
    node_set.set[i_node, i_field] = node_field_value
    return nothing
end

function Base.getindex(node_set :: NodeSet, i_nodes :: T, field_name :: String) where T <: AbstractVector{Int64}
    return node_set[field_name][i_nodes]
end

function Base.setindex!(node_set :: NodeSet, node_field_values, i_nodes :: T, field_name :: String) where T <: AbstractVector{Int64}
    i_field = get_field_index(node_set, field_name)
    node_set.set[i_nodes, i_field] = node_field_values
    return nothing
end


## ITERATION

function Base.iterate(node_set :: NodeSet)
    return length(node_set) <= 0 ? nothing : (node_set[begin], firstindex(node_set))    # (first_item, state)
end

function Base.iterate(node_set :: NodeSet, state :: Int64)
    return length(node_set) <= state ? nothing : (node_set[state + 1], state + 1)        # (i+1th item, i+1th state)
end

function Base.IteratorSize(T :: Type{NodeSet})
    return Base.HasShape{1}()
end

function Base.IteratorEltype(T :: Type{NodeSet})
    return Base.HasEltype()
end

function Base.eltype(T :: Type{NodeSet})
    return Type{Node}
end

function Base.length(node_set :: NodeSet)
    return size(node_set.set, 1)
end

function Base.size(node_set :: NodeSet)
    return size(node_set.set)
end

function Base.size(node_set :: NodeSet, dim)
    return size(node_set.set, dim)
end

function Base.isdone(node_set :: NodeSet)
    return length(node_set) <= 0
end

function Base.isdone(node_set :: NodeSet, state :: Int)
    return length(node_set) <= state
end
