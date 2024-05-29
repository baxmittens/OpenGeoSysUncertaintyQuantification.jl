using OpenGeoSysUncertaintyQuantification
using Test
import Pkg
Pkg.develop("OpenGeoSysUncertaintyQuantification")

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    println(readdir())
    cd("ex1") #has to be called from project directory
    println(readdir())
    include("run_ex1.jl")
end