using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
OGS_PRJ_PATH = joinpath(OpenGeoSysUncertaintyQuantification.ogs_prj_folder(), "Consolidation_PHS")
projectfile= joinpath(OGS_PRJ_PATH,"prj","point_heat_source_2D.prj")
additionalprojecfilespath=joinpath(OGS_PRJ_PATH,"mesh")
user_functions_file = joinpath(PATH, "user_functions.jl")
output_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
stoch_params_xml = joinpath(PATH, "StochasticParameters.xml")
samplemethod_output_xml = joinpath(PATH, "SampleMethodParams.xml")
outputpath=joinpath(PATH,"Res")

simcall = "/Users/maximilianbittens/Documents/GitHub/OpenGeoSys/build/release/bin/ogs"
#simcall = "ogs" # ogs binary is in path, otherwise put your path/to/bin/ogs here
#simcall = OpenGeoSysUncertaintyQuantification.install_ogs()
@info "simcall: $simcall"

postprocfiles=["PointHeatSource_quarter_002_2nd.xdmf"]
stochmethod=MonteCarlo
n_workers = 21

stochparampathes = loadStochasticParameters(stoch_params_xml)

# generate stochastic model
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

#generate sample method model
samplemethodparams = generateSampleMethodModel(stochasticmodelparams, samplemethod_output_xml)
# alter sample method params
samplemethodparams.nshots = 5000
write(samplemethodparams)