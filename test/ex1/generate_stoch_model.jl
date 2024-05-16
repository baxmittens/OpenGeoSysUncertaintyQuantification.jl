using OpenGeoSysUncertaintyQuantification

projectfile="./project/point_heat_source_2D.prj"
simcall="ogs" # ogs binary has to be in path. otherwise insert your "path/to/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["PointHeatSource_quarter_002_2nd.xdmf"]
outputpath="./Res"
stochmethod=AdaptiveHierarchicalSparseGrid
n_workers = 10

stochparampathes = loadStochasticParameters("StochasticParameters.xml")
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod,
	n_workers)

# alter the stochastic parameters
stoch_params = stoch_parameters(stochasticmodelparams)
@assert contains(stoch_params[1].path, "AqueousLiquid")
stoch_params[1].dist = Normal(0.6,0.175)
stoch_params[1].lower_bound = 0.3
stoch_params[1].upper_bound = 0.9
stoch_params[2].dist = Normal(0.45,0.15)
stoch_params[2].lower_bound = 0.1
stoch_params[2].upper_bound = 0.8

write(stochasticmodelparams)

samplemethodparams = generateSampleMethodModel(stochasticmodelparams)

#alter sample method params
samplemethodparams.init_lvl = 4
samplemethodparams.maxlvl = 12
samplemethodparams.tol = 0.025

write(samplemethodparams)