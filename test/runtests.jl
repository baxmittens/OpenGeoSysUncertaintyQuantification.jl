using OpenGeoSysUncertaintyQuantification
using Test

@info "Running tests"

TESTDIR = "./tmp_test_dir"
EXAMPLEDIR = "./Examples/ASG_Point_Heat_Source/"

if isdir(TESTDIR)
    @info "deleting $TESTDIR"
    run(`rm -rf $TESTDIR`)
end

cp(EXAMPLEDIR, TESTDIR)

@testset "Stochastic parameters" begin
    include(joinpath(TESTDIR, "generate_stoch_params_file.jl"))
end

@testset "Stochastic model setup" begin
    include(joinpath(TESTDIR, "generate_stoch_model_lowres.jl"))
end

@testset "Project setup" begin
    include("test_project_setup.jl")
end

@testset "Utils" begin
    include("test_utils.jl")
end

@testset "OGS run" begin
    include(joinpath(TESTDIR, "start.jl"))
    @test maximum(varval["temperature_interpolated"][:,end]) > 1e7 && maximum(varval["temperature_interpolated"][:,end]) < 1e8
end