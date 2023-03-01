#include("../../src/OGSUQ.jl")
using OGSUQ
using DistributedSparseGrids
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid
using Distributions
using VTUFileHandler


projectfile="./project/disc_with_hole.prj"
simcall="/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["disc_with_hole_ts_4_t_1.000000.vtu"]

#pathes = generatePossibleStochasticParameters(projectfile)
stochparampathes = loadStochasticParameters()
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes)

samplemethodparams = generateSampleMethodModel(stochasticmodelparams)

ogsuqparams = OGSUQParams(stochasticmodelparams, samplemethodparams)
ogsuqparams = OGSUQParams(OGSUQ.filename(stochasticmodelparams), OGSUQ.filename(samplemethodparams))


ogsuqasg = OGSUQ.init(ogsuqparams)
OGSUQ.start!(ogsuqasg)