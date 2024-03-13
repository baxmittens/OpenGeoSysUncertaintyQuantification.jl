using OpenGeoSysUncertaintyQunatification
using Test

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end