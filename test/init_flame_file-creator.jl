"""
Creates `init_flame.in` files from a selected `sunset_code:oned` branch run. This stitches
the flame files for each mpi process into a single init_flame file.

Script args:
1   input flame file dir
2   frame
3   n_slots 
4   output `init_flame.in` dir
# 5   output file name (just `init_flame.in` atm)

flame file output fields are:
1   x
2   y
3   u
4   v
5   w
6   ro
7   roE
8   T
9   p
10  Y1
11  Y2 
etc
"""

using Dates, Printf

println("Parsing args")

arg_flame_file_dir = ARGS[1]
arg_frame = 1
arg_n_slots = 1
arg_out_dir = ARGS[4]
arg_out_name = "init_flame.in"

if !isdir(arg_out_dir)
    throw(ArgumentError("Output directory not found"))
elseif isfile(joinpath(arg_out_dir, arg_out_name))
    nice_dt = replace(string(Dates.now()), ":" => "-")
    arg_out_name = string(arg_out_name, ".", nice_dt)
end

arg_frame = tryparse(Int64, ARGS[2])
arg_n_slots = tryparse(Int64, ARGS[3])

flame_files = [
    joinpath(arg_flame_file_dir, string("flame", 10000 + i_slot, "_", arg_frame))
    for i_slot in 0:(arg_n_slots - 1)
]
println("Reading from flame files: ", flame_files)
data_all = Vector{Float64}[]
line_length = -1

for flame_file in flame_files
    for line in eachline(flame_file)
        line_strings = filter(str -> str != "", split(line, " "))
        line_vals = tryparse.(Float64, line_strings)
        # println(length(line_vals), " \t", line_vals)
        if length(line_vals) != line_length && line_length != -1
            throw(ArgumentError("Line length varying, inconsistent file data"))
        elseif line_length == -1
            global line_length = length(line_vals)
        end
        push!(data_all, line_vals)
    end
end

println("Writing to file: ", joinpath(arg_out_dir, arg_out_name))

sprintf(val :: Float64) = begin
    str = @sprintf "%.7e" val
    replace(str, "e" => "d")
end

open(joinpath(arg_out_dir, arg_out_name), "w") do out_file
    write(out_file, string(length(data_all)))
    write(out_file, "\n")
    for line_vals in data_all
        write(out_file, join(sprintf.(line_vals), " \t"))
        write(out_file, "\n")
    end
end

printstyled("\nEnd of script. \n"; color = :green)

