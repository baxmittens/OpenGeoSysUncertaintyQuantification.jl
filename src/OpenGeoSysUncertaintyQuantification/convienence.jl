ogs6_modeldef(ogsparams::OGS6ProjectParams) = read(Ogs6ModelDef, ogsparams.projectfile)
ogs6_modeldef(stochparams::StochasticOGSModelParams) = ogs6_modeldef(stochparams.ogsparams)
ogs6_modeldef(ogsuqparams::OGSUQParams) = ogs6_modeldef(ogsuqparams.stochasticmodelparams)
ogs6_modeldef(ogsuq::AbstractOGSUQ) = ogs6_modeldef(ogsuq.ogsuqparams)

ogs6_simcall(ogsparams::OGS6ProjectParams) = ogsparams.simcall
ogs6_simcall(stochparams::StochasticOGSModelParams) = ogs6_simcall(stochparams.ogsparams)
ogs6_simcall(ogsuqparams::OGSUQParams) = ogs6_simcall(ogsuqparams.stochasticmodelparams)
ogs6_simcall(ogsuq::AbstractOGSUQ) = ogs6_simcall(ogsuq.ogsuqparams)

ogs6_outputpath(ogsparams::OGS6ProjectParams) = ogsparams.outputpath
ogs6_outputpath(stochparams::StochasticOGSModelParams) = ogs6_outputpath(stochparams.ogsparams)
ogs6_outputpath(ogsuqparams::OGSUQParams) = ogs6_outputpath(ogsuqparams.stochasticmodelparams)
ogs6_outputpath(ogsuq::AbstractOGSUQ) = ogs6_outputpath(ogsuq.ogsuqparams)

ogs6_additionalprojecfilespath(ogsparams::OGS6ProjectParams) = ogsparams.additionalprojecfilespath
ogs6_additionalprojecfilespath(stochparams::StochasticOGSModelParams) = ogs6_additionalprojecfilespath(stochparams.ogsparams)
ogs6_additionalprojecfilespath(ogsuqparams::OGSUQParams) = ogs6_additionalprojecfilespath(ogsuqparams.stochasticmodelparams)
ogs6_additionalprojecfilespath(ogsuq::AbstractOGSUQ) = ogs6_additionalprojecfilespath(ogsuq.ogsuqparams)

ogs6_postprocfiles(stogsparamsochparams::OGS6ProjectParams) = ogsparams.postprocfiles
ogs6_postprocfiles(stochparams::StochasticOGSModelParams) = ogs6_postprocfiles(stochparams.ogsparams)
ogs6_postprocfiles(ogsuqparams::OGSUQParams) = ogs6_postprocfiles(ogsuqparams.stochasticmodelparams)
ogs6_postprocfiles(ogsuq::AbstractOGSUQ) = ogs6_postprocfiles(ogsuq.ogsuqparams)

stoch_parameters(stochasticmodelparams::StochasticOGSModelParams) = stochasticmodelparams.stochparams
stoch_parameters(ogsuqparams::OGSUQParams) = stoch_parameters(ogsuqparams.stochasticmodelparams)
stoch_parameters(ogsuq::AbstractOGSUQ) = stoch_parameters(ogsuq.ogsuqparams)

stoch_samplemethod(stochasticmodelparams::StochasticOGSModelParams) = stochasticmodelparams.samplemethod
stoch_samplemethod(ogsuqparams::OGSUQParams) = stoch_samplemethod(ogsuqparams.stochasticmodelparams)
stoch_samplemethod(ogsuq::AbstractOGSUQ) = stoch_samplemethod(ogsuq.ogsuqparams)