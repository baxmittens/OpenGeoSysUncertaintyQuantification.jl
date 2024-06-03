using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!
using Distributed

PATH = "./"
#PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
stochogsmodel_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
samplemethod_xml = joinpath(PATH, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(stochogsmodel_xml, samplemethod_xml)
ogsuqasg = init(ogsuqparams)

@everywhere begin
	import XDMFFileHandler 
	push!(XDMFFileHandler.interpolation_keywords, "Si")
	push!(XDMFFileHandler.interpolation_keywords, "darcy_velocity")
end

start!(ogsuqasg)

ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.001
expval,asg_expval = 𝔼(ogsuqasg);
ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.00001
varval,asg_varval = variance(ogsuqasg, expval);

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
#
#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->norm(x["Si"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for norm(Si)")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->norm(x["Si"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for norm(Si)")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->norm(x["Si"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for norm(Si)")))
#
#display(PlotlyJS.plot([PlotlyJS.scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->norm(x["darcy_velocity"]))], PlotlyJS.Layout(title="ASG-Surrogateresponse function ASG(x) for norm(darcy_velocity)")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->norm(x["darcy_velocity"]))], PlotlyJS.Layout(title="ASG(x)*pdf(x) for norm(darcy_velocity)")))
#display(PlotlyJS.plot([PlotlyJS.scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->norm(x["darcy_velocity"]))], PlotlyJS.Layout(title="(ASG(x)-𝔼(x))^2*pdf(x) for norm(darcy_velocity)")))