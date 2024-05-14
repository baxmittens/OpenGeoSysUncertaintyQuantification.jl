using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids.idstring
import Ogs6InputFileHandler: format_ogs_path

ogsuqparams = OGSUQParams("StochasticOGSModelParams.xml", "SampleMethodParams.xml")
ogsuqasg = init(ogsuqparams)
morris_means, morris_means_abs = start!(ogsuqasg)
stoparams = stoch_parameters(ogsuqasg)

for i in 1:length(stoparams)
	name = format_ogs_path(stoparams[i].path)
	write(morris_means_abs[i], name*".xdmf", name*".h5")
end


#expval,asg_expval = 𝔼(ogsuqasg)
#varval,asg_varval = variance(ogsuqasg, expval)

#outputpath = ogsuqparams.stochasticmodelparams.ogsparams.outputpath
#collocidstr = idstring(first(ogsuqasg.asg))
#postprocfile = first(ogsuqparams.stochasticmodelparams.ogsparams.postprocfiles)
#xdmf_proto = XDMF3File(joinpath(outputpath,collocidstr,postprocfile))
#expvalxdmf = similar(xdmf_proto)
#varvalxdmf = similar(xdmf_proto)
#expvalxdmf.idata = expval
#varvalxdmf.idata = varval
#
#write(expvalxdmf, "expval.xdmf", "expval.h5")
#write(varvalxdmf, "varval.xdmf", "varval.h5")
#
#
#import DistributedSparseGrids: AbstractCollocationPoint, AbstractHierarchicalCollocationPoint, AbstractHierarchicalSparseGrid, numlevels, coord, pt_idx, i_multi, level, scaling_weight
#include(joinpath("..","..","..","DistributedSparseGrids","src","AdaptiveSparseGrids","plotting.jl"))
#
#plot([scatter3d(ogsuqasg.asg), surface_inplace_ops(ogsuqasg.asg, 20, x->maximum(x["temperature_interpolated"]))])
#plot([scatter3d(asg_expval), surface_inplace_ops(asg_expval, 50, x->maximum(x["temperature_interpolated"]))])
#plot([scatter3d(asg_varval), surface_inplace_ops(asg_varval, 50, x->maximum(x["temperature_interpolated"]))])

