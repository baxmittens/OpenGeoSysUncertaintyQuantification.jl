using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!

ogsuqparams = OGSUQParams("StochasticOGSModelParams.xml", "SampleMethodParams.xml")
ogsuqasg = init(ogsuqparams)
start!(ogsuqasg)
expval,asg_expval = 𝔼(ogsuqasg)
varval,asg_varval = variance(ogsuqasg, expval)

write(expval, "expval.xdmf", "expval.h5")
write(varval, "varval.xdmf", "varval.h5")

# import Pkg
# Pkg.add("PlotlyJS")
# Pkg.add("DistributedSparseGridsPlotting")

using PlotlyJS
using DistributedSparseGridsPlotting
display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogate response function ASG(x) - max. temp")))
display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) - max. temp")))
display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) - max. temp")))
