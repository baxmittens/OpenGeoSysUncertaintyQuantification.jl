using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!

ogsuqparams = OGSUQParams("altered_StochasticOGSModelParams.xml", "altered_SampleMethodParams.xml")
ogsuqasg = init(ogsuqparams)
start!(ogsuqasg)
expval,asg_expval = 𝔼(ogsuqasg)
varval,asg_varval = variance(ogsuqasg, expval)

outputpath = ogsuqparams.stochasticmodelparams.ogsparams.outputpath
collocidstr = idstring(first(ogsuqasg.asg))
postprocfile = first(ogsuqparams.stochasticmodelparams.ogsparams.postprocfiles)
xdmf_proto = XDMF3File(joinpath(outputpath,collocidstr,postprocfile))
expvalxdmf = similar(xdmf_proto)
varvalxdmf = similar(xdmf_proto)
expvalxdmf.idata = expval
varvalxdmf.idata = varval

write(expvalxdmf, "expval.xdmf", "expval.h5")
write(varvalxdmf, "varval.xdmf", "varval.h5")

## commented due to problems with Plotly if imported on remote workers (which happens by calling `using OpenGeoSysUncertaintyQuantification`)
#import DistributedSparseGrids: AbstractCollocationPoint, AbstractHierarchicalCollocationPoint, AbstractHierarchicalSparseGrid, numlevels, coord, pt_idx, i_multi, level, scaling_weight
## load plotting functions manually from DistributedSparseGrids source folder (this works if it is in .julia/dev)
#include(joinpath("..","..","..","DistributedSparseGrids","src","AdaptiveSparseGrids","plotting.jl"))
#PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogate response function ASG(x) - max. temp"))
#PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) - max. temp"))
#PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) - max. temp"))
