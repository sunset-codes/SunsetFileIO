### FIELDS

FieldValue = Union{Float64, Int64, Bool}

struct Field
    name :: String
    type :: Type
end


axes_strings = ["x", "y", "z"]
v_strings = [string("v_", axes_strings[i_axis]) for i_axis in 1:3]
n_strings = [string("n_", axes_strings[i_axis]) for i_axis in 1:3]
Y_string(i_Y) = string("Y", i_Y)
ω_string(i_Y) = string("ω", i_Y)

i_strings = [string("i_", axes_strings[i_axis]) for i_axis in 1:3]

position_fields = [Field(axes_strings[i_axis], Float64) for i_axis in 1:3]
s_field = Field("s", Float64)
h_field = Field("h", Float64)
type_field = Field("type", Int64)
n_fields = [Field(n_strings[i_axis], Float64) for i_axis in 1:3]
rho_field = Field("rho", Float64)
v_fields = [Field(v_strings[i_axis], Float64) for i_axis in 1:3]
vort_field = Field("vort", Float64)
T_field = Field("T", Float64)
p_field = Field("p", Float64)
hrr_field = Field("hrr", Float64)
Y_fields(Y) = [Field(Y_string(i_Y), Float64) for i_Y in 1:Y]
ω_fields(Y) = [Field(ω_string(i_Y), Float64) for i_Y in 1:Y]
rhoE_field = Field("rhoE", Float64)
proc_field = Field("proc", Int64)

i_fields = [Field(i_strings[i_axis], Int64) for i_axis in 1:3]
s_interp_field = Field("s interp", Float64)

nodes_fields(D) = Field[
    position_fields[1:D]...,
    s_field,
    h_field,
    type_field,
]
fields_fields(D, Y; has_ω = false) = begin
    fields = Field[
        rho_field,
        v_fields[1:D]...,
        vort_field,
        T_field,
        p_field,
        hrr_field,
        Y_fields(Y)...,
    ]
    if has_ω
        push!(fields, ω_fields(Y)...)
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
    v_fields[1:D]...,
    vort_field,
    rho_field,
    rhoE_field,
    T_field,
    p_field,
    Y_fields(Y)...,
]

