### FIELDS

FieldValue = Union{Float64, Int64, Bool}

struct Field
    name :: String
    type :: Type
end


axes_strings = ["x", "y", "z"]
v_string(i_axis) = string("v_", axes_strings[i_axis])
n_string(i_axis) = string("n_", axes_strings[i_axis])
Y_string(i_Y) = string("Y", i_Y)

position_fields(D) = [Field(axes_strings[i_axis], Float64) for i_axis in 1:D]
s_field = Field("s", Float64)
h_field = Field("h", Float64)
type_field = Field("type", Int64)


n_fields(D) = [Field(n_string(i_axis), Float64) for i_axis in 1:D]

rho_field = Field("rho", Float64)
v_fields(D) = [Field(v_string(i_axis), Float64) for i_axis in 1:D]
vort_field = Field("vort", Float64)
T_field = Field("T", Float64)
p_field = Field("p", Float64)
hrr_field = Field("hrr", Float64)
Y_fields(Y) = [Field(Y_string(i_Y), Float64) for i_Y in 1:Y]

rhoE_field = Field("rhoE", Float64)

nodes_fields(D) = Field[
    position_fields(D)...,
    s_field,
    h_field,
    type_field,
]
fields_fields(D, Y) = Field[
    rho_field,
    v_fields(D)...,
    vort_field,
    T_field,
    p_field,
    hrr_field,
    Y_fields(Y)...,
]
IPART_fields(D) = Field[
    position_fields(D)...,
    type_field,
    n_fields(D)...,
    s_field,
]
flame_fields(D, Y) = Field[
    position_fields(D)...,
    v_fields(D)...,
    vort_field,
    rho_field,
    rhoE_field,
    T_field,
    p_field,
    Y_fields(Y)...,
]


