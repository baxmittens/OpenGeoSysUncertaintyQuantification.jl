using OpenGeoSysUncertaintyQuantification
using Test

@info "Running tests"

TESTDIR = "./tmp_test_dir"
EXAMPLEDIR = "./Examples/OGSUQ/ASG_Consolidation_PHS/"

if isdir(TESTDIR)
    @info "deleting $TESTDIR"
    run(`rm -rf $TESTDIR`)
end
mkdir(TESTDIR)
cp(joinpath(EXAMPLEDIR, "generate_stoch_params_file.jl"), joinpath(TESTDIR, "generate_stoch_params_file.jl"))
cp(joinpath(EXAMPLEDIR, "generate_stoch_model_lowres.jl"), joinpath(TESTDIR,"generate_stoch_model_lowres.jl"))
cp(joinpath(EXAMPLEDIR, "start.jl"), joinpath(TESTDIR,"start.jl"))

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