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

expval = 𝔼(ogsuqasg)
varval = variance(ogsuqasg, expval)

# XDMF cannot have '/' on name or h5 spec, therefore the path is the third argument 
# Base.write(xdmf3f::XDMF3File, name::String, newh5::String, path="./")
write(expval, "expval.xdmf", "expval.h5", PATH)
write(varval, "varval.xdmf", "varval.h5", PATH)
