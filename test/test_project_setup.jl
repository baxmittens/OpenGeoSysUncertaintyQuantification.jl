file_stoch_model = joinpath(TESTDIR, "StochasticOGSModelParams.xml")
file_sample_params = joinpath(TESTDIR, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(file_stoch_model, file_sample_params)

@test ogsuqparams.stochasticmodelparams.samplemethod == AdaptiveHierarchicalSparseGrid