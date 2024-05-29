using OpenGeoSysUncertaintyQuantification
using Test

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    println(readdir())
    prj_dir = joinpath(@__DIR__,"ex1")
    cd(prj_dir) #has to be called from project directory
    println(readdir())
    include("run_ex1.jl")
end