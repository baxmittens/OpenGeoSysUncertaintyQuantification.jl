using OpenGeoSysUncertaintyQuantification
using Test

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    include("./ex1/run_ex1.jl")
end