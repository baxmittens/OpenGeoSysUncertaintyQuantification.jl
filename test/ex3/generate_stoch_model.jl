using OGSUQ

projectfile="./project/point_heat_source_2D.prj"
simcall="/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["PointHeatSource_ts_10_t_50000.000000.vtu"]
outputpath="./Res"
stochmethod=AdaptiveHierarchicalSparseGrid

stochparampathes = loadStochasticParameters("altered_PossibleStochasticParameters.xml")
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod)

samplemethodparams = generateSampleMethodModel(stochasticmodelparams)