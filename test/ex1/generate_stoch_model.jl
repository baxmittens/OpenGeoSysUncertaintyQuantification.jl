using OpenGeoSysUncertaintyQuantification

__relpath__ = relpath(@__DIR__, "./")
projectfile= joinpath(__relpath__,"project","point_heat_source_2D.prj")
user_functions_file = joinpath(__relpath__, "user_functions.jl")
output_xml = joinpath(__relpath__, "StochasticOGSModelParams.xml")
stoch_params_xml = joinpath(__relpath__, "StochasticParameters.xml")
samplemethod_output_xml = joinpath(__relpath__, "SampleMethodParams.xml")

simcall="ogs" # ogs binary has to be in path. otherwise insert your "path/to/ogs"
if haskey(ENV, "OGS_BINARY")
	@info "using $(ENV["OGS_BINARY"]) as binary"
	simcall = ENV["OGS_BINARY"]
end
additionalprojecfilespath=joinpath(__relpath__,"mesh")
outputpath=joinpath(__relpath__,"Res")
postprocfiles=["PointHeatSource_quarter_002_2nd.xdmf"]
stochmethod=AdaptiveHierarchicalSparseGrid
n_workers = 4

stochparampathes = loadStochasticParameters(stoch_params_xml)

stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod,
	n_workers,
	user_functions_file,
	output_xml)

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
samplemethodparams = generateSampleMethodModel(stochasticmodelparams, samplemethod_output_xml)

#alter sample method params
samplemethodparams.init_lvl = 4
samplemethodparams.maxlvl = 12
samplemethodparams.tol = 0.025

write(samplemethodparams)