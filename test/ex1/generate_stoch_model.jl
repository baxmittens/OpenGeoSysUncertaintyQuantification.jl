using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
projectfile= joinpath(PATH,"project","point_heat_source_2D.prj")
user_functions_file = joinpath(PATH, "user_functions.jl")
output_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
stoch_params_xml = joinpath(PATH, "StochasticParameters.xml")
samplemethod_output_xml = joinpath(PATH, "SampleMethodParams.xml")

simcall = "ogs" # ogs binary is in path, otherwise put your path/to/bin/ogs here
if haskey(ENV, "OGS_BINARY") # installed with install_ogs.sh
	@info "using $(ENV["OGS_BINARY"]) as binary"
	simcall = ENV["OGS_BINARY"]
elseif isfile(joinpath(PATH, "../ogspyvenv/bin/ogs")) # for GitHub Action / testing
	@info "using ./ogspyvenv/bin/ogs as binary"
	simcall = "./ogspyvenv/bin/ogs"
else
	@info "using ogs as binary"
end
additionalprojecfilespath=joinpath(PATH,"mesh")
outputpath=joinpath(PATH,"Res")
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

# alter sample method params
# reduce init and max level for CI / GitHub Action
samplemethodparams.init_lvl = 3
samplemethodparams.maxlvl = 4
#samplemethodparams.init_lvl = 4
#samplemethodparams.maxlvl = 12
samplemethodparams.tol = 0.025

write(samplemethodparams)