### FIELDS

FieldValueScalar = Union{Float64, Int64, Bool}
FieldValue = Union{FieldValueScalar, Vector{Int64}}

struct Field
    name :: String
    type :: Type
end


axes_strings = ["x", "y", "z"]
u_strings = [string("u_", axes_strings[i_axis]) for i_axis in 1:3]
n_strings = [string("n_", axes_strings[i_axis]) for i_axis in 1:3]
Y_string(i_Y) = string("Y", i_Y)
ω_string(i_Y) = string("ω", i_Y)
i_strings = [string("i_", axes_strings[i_axis]) for i_axis in 1:3]

position_fields = [Field(axes_strings[i_axis], Float64) for i_axis in 1:3]
s_field = Field("s", Float64)
h_field = Field("h", Float64)
type_field = Field("type", Int64)
n_fields = [Field(n_strings[i_axis], Float64) for i_axis in 1:3]
proc_field = Field("proc", Int64)

rho_field = Field("rho", Float64)
u_fields = [Field(u_strings[i_axis], Float64) for i_axis in 1:3]
vort_field = Field("vort", Float64)
T_field = Field("T", Float64)
p_field = Field("p", Float64)
hrr_field = Field("hrr", Float64)
Y_fields(Y) = [Field(Y_string(i_Y), Float64) for i_Y in 1:Y]
ω_fields(Y) = [Field(ω_string(i_Y), Float64) for i_Y in 1:Y]
rhoE_field = Field("rhoE", Float64)

i_fields = [Field(i_strings[i_axis], Int64) for i_axis in 1:3]
s_interp_field = Field("s interp", Float64)

node_linkage_field = Field("node_linkage", Vector{Float64})
vol_field = Field("vol", Float64)

nodes_fields(D) = Field[
    position_fields[1:D]...,
    s_field,
    h_field,
    type_field,
]
fields_fields(D, Y; has_ω = true, has_vol = true) = begin
    fields = Field[
        rho_field,
        u_fields[1:D]...,
        vort_field,
        T_field,
        p_field,
        hrr_field,
        Y_fields(Y)...,
    ]
    if has_ω
        push!(fields, ω_fields(Y)...)
    end
    if has_vol
        push!(fields, vol_field)
    end
    return fields
end
IPART_fields(D) = Field[
    position_fields[1:D]...,
    type_field,
    n_fields[1:D]...,
    s_field,
]
flame_fields(D, Y) = Field[
    position_fields[1:D]...,
    u_fields[1:D]...,
    vort_field,
    rho_field,
    rhoE_field,
    T_field,
    p_field,
    Y_fields(Y)...,
]

