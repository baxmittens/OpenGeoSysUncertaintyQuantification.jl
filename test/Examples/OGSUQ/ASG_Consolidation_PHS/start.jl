using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
stochogsmodel_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
samplemethod_xml = joinpath(PATH, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(stochogsmodel_xml, samplemethod_xml)
ogsuqasg = init(ogsuqparams)
start!(ogsuqasg)
#ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.0001
expval,asg_expval = 𝔼(ogsuqasg)
#ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.0001
varval,asg_varval = variance(ogsuqasg, expval)

# XDMF cannot have '/' on name or h5 spec, therefore the path is the third argument 
# Base.write(xdmf3f::XDMF3File, name::String, newh5::String, path="./")
write(expval, "expval.xdmf", "expval.h5", PATH)
write(varval, "varval.xdmf", "varval.h5", PATH)

# import Pkg
# Pkg.add("PlotlyJS")
# Pkg.add("DistributedSparseGridsPlotting")

#using PlotlyJS
#using DistributedSparseGridsPlotting
#using LinearAlgebra
#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for max. temp")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for max. temp")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 20, x->maximum(x["temperature_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for max. temp")))

#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for max. press")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for max. press")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["pressure_interpolated"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for max. press")))