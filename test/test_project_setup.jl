file_stoch_model = "./ex1/StochasticOGSModelParams.xml"
file_sample_params = "./ex1/SampleMethodParams.xml"

ogsuqparams = OGSUQParams(file_stoch_model, file_sample_params)

@test ogsuqparams.stochasticmodelparams.samplemethod == AdaptiveHierarchicalSparseGrid