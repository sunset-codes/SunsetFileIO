# SunsetFileIO
This package is designed for the ease of use of the [sunset-flames](https://github.com/sunset-codes/sunset-flames) CFD code. For best use, clone the [sunset-tools](https://github.com/sunset-codes/sunset-tools) repo which contains scripts which best use this package.

NB: For the moment I don't plan on adding this package as a fully fledged official Julia package because, frankly, that wouldn't help.

If anything breaks or you don't understand something, let me know!

## Prerequisites
- Julia 1.10
  - You should probably install this via [juliaup](https://github.com/JuliaLang/juliaup)
- A bunch of Julia packages which are easy to install:
  - `Random.jl`
  - `Dates.jl`
  - `WriteVTK.jl`
  - `DelimitedFiles.jl`

## Installation
1. Clone this repository

```bash
git clone https://github.com/sunset-codes/SunsetFileIO [<some directory>]
```

2. Add the directory. This can be done one of two ways:
  - The usual way, for usage without development - add the path to the package:

```julia
julia> ]

(@v1.10) pkg> add <path to SunsetFileIO directory>
```

  - The less usual way, for usage where you develop SunsetFileIO (what I do):

```julia
julia> ]

(@v1.10) pkg> dev <path to SunsetFileIO directory>
```

3. Ta-dah, you're done! As long as you type `using SunsetFileIO` before using one of the provided functions (listed in `SunsetFileIO.jl` under `export`), you'll have access. Note that this is already written into the scripts in [sunset-tools](https://github.com/sunset-codes/sunset-tools), so all you have to do there is use the scripts as usual.

