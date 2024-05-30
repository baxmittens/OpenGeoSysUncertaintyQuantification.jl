file_stoch_model = joinpath(TESTDIR, "StochasticOGSModelParams.xml")
file_sample_params = joinpath(TESTDIR, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(file_stoch_model, file_sample_params)

stochparams = stoch_parameters(ogsuqparams)

unit_cube_val = rand(Float64)
stoch_val = CPtoStoch(unit_cube_val, first(stochparams))
unit_cube_val_prime = StochtoCP(stoch_val, first(stochparams))

@test isapprox(unit_cube_val,unit_cube_val_prime,atol=1e-9)