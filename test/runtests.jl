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
    include("ex1/generate_stoch_model_lowres.jl")
    include("ex1/start.jl")
    @test maximum(varval["temperature_interpolated"][:,end]) > 1e7 && maximum(varval["temperature_interpolated"][:,end]) < 1e8
end