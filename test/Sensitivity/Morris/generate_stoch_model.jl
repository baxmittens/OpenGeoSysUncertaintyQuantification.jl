using OpenGeoSysUncertaintyQuantification

projectfile="./project/point_heat_source_2D.prj"
simcall="/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["PointHeatSource_quarter_002_2nd.xdmf"]
outputpath="./Res"
stochmethod=MonteCarloMorris

stochparampathes = loadStochasticParameters("StochasticParameters.xml")
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod)

samplemethodparams = generateSampleMethodModel(stochasticmodelparams)