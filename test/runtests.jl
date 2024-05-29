using OpenGeoSysUncertaintyQuantification
using Test

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    cd("./ex1") #has to be called from project directory
    include("./run_ex1.jl")
end