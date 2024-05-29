using OpenGeoSysUncertaintyQuantification
using Test

@info "Running tests"

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    include("ex1/generate_stoch_params_file.jl")
    include("ex1/generate_stoch_model.jl")
    include("ex1/start.jl")
end