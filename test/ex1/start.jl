using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!

__relpath__ = relpath(@__DIR__, "./")
stochogsmodel_xml = joinpath(__relpath__, "StochasticOGSModelParams.xml")
samplemethod_xml = joinpath(__relpath__, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(stochogsmodel_xml, samplemethod_xml)
ogsuqasg = init(ogsuqparams)
start!(ogsuqasg)
expval,asg_expval = 𝔼(ogsuqasg)
varval,asg_varval = variance(ogsuqasg, expval)


write(expval, joinpath(__relpath__, "expval.xdmf"), joinpath(__relpath__, "expval.h5"))
write(varval, joinpath(__relpath__, "varval.xdmf"), joinpath(__relpath__, "varval.h5"))



# import Pkg
# Pkg.add("PlotlyJS")
# Pkg.add("DistributedSparseGridsPlotting")

#using PlotlyJS
#using DistributedSparseGridsPlotting
#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for max. temp")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for max. temp")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for max. temp")))

#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for max. press")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for max. press")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for max. press")))