file_stoch_model = "./ex1/altered_StochasticOGSModelParams.xml"
file_sample_params = "./ex1/altered_SampleMethodParams.xml"

ogsuqparams = OGSUQParams(file_stoch_model, file_sample_params)

@test ogsuqparams.stochasticmodelparams.samplemethod == AdaptiveHierarchicalSparseGrid