"""
A test to see how WriteVTK works with the sort of data I will use (point data which is unstructured).

Writing is best performed compressed, appended and in binary.
"""

using WriteVTK, Dates


x_values = 0.0:1.0:100.0
y_values = 0.0:1.0:100.0
z_values = 0.0

println(length(x_values), " ", length(y_values), " ", length(z_values))

x = vec([x_val for x_val in x_values, _ in y_values, _ in z_values])
y = vec([y_val for _ in x_values, y_val in y_values, _ in z_values])
z = vec([z_val for _ in x_values, _ in y_values, z_val in z_values])

println(length(x), " ", length(y), " ", length(z))

connectivity = 1:length(x) |> collect
cells = [MeshCell(VTKCellTypes.VTK_VERTEX, [con]) for con in connectivity]  # Cells are given by veritces which are connected to the point they correspond to

out_file_path = joinpath(@__DIR__, string("test-vtk-100.", Dates.now(), ".vtu"))
vtk_grid(
    out_file_path,
    transpose([x y z]),
    cells;
    ascii = true,
    append = false
) do vtu_file
    vtu_file["coords"] = transpose([x y z])
    vtu_file["x"] = x
    vtu_file["y"] = y
    vtu_file["z"] = z
end