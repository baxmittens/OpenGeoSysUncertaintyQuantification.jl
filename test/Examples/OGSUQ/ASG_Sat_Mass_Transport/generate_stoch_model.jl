using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
OGS_PRJ_PATH = joinpath(OpenGeoSysUncertaintyQuantification.ogs_prj_folder(), "Saturated_Mass_Transport")
projectfile= joinpath(OGS_PRJ_PATH,"prj","DiffusionAndStorageAndAdvectionAndDispersionHalf.prj")
additionalprojecfilespath=joinpath(OGS_PRJ_PATH,"misc")
user_functions_file = joinpath(PATH, "user_functions.jl")
output_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
stoch_params_xml = joinpath(PATH, "StochasticParameters.xml")
samplemethod_output_xml = joinpath(PATH, "SampleMethodParams.xml")
outputpath=joinpath(PATH,"Res")

# hierarchical sparse grid level
INIT_LVL = 4
MAX_LVL = 12

simcall = "/Users/maximilianbittens/Documents/GitHub/OpenGeoSys/build/release/bin/ogs"
#simcall = "ogs" # ogs binary is in path, otherwise put your path/to/bin/ogs here
#simcall = OpenGeoSysUncertaintyQuantification.install_ogs()
@info "simcall: $simcall"

postprocfiles=["DiffusionAndStorageAndAdvectionAndDispersionHalf_square_1x1_quad_1e3.xdmf"]
stochmethod=AdaptiveHierarchicalSparseGrid
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
stoch_params[1].dist = Normal(0.55,0.25)
stoch_params[1].lower_bound = 0.1
stoch_params[1].upper_bound = 1.0
stoch_params[2].dist = Normal(0.55,0.25)
stoch_params[2].lower_bound = 0.1
stoch_params[2].upper_bound = 1.0
write(stochasticmodelparams)

#generate sample method model
samplemethodparams = generateSampleMethodModel(stochasticmodelparams, samplemethod_output_xml)
# alter sample method params
samplemethodparams.init_lvl = INIT_LVL
samplemethodparams.maxlvl = MAX_LVL
samplemethodparams.tol = 0.005
write(samplemethodparams)