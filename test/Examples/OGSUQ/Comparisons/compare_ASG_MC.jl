using OpenGeoSysUncertaintyQuantification
import XDMFFileHandler
using LinearAlgebra

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
push!(XDMFFileHandler.interpolation_keywords, "Si")
push!(XDMFFileHandler.interpolation_keywords, "darcy_velocity")

#try
expval1 = XDMF3File(joinpath(PATH, "..", "ASG_Sat_Mass_Transport/expval.xdmf"));
expval2 = XDMF3File(joinpath(PATH, "..", "MC_Sat_Mass_Transport/expval.xdmf"));

varval1 = XDMF3File(joinpath(PATH, "..", "ASG_Sat_Mass_Transport/varval.xdmf"));
varval2 = XDMF3File(joinpath(PATH, "..", "MC_Sat_Mass_Transport/varval.xdmf"));

diffexpval = (((expval1-expval2)^2.0)^0.5)
diffvar = (((varval1-varval2)^2.0)^0.5)

println(norm(diffexpval["Si"]))
println(norm(diffvar["Si"]))

write(diffexpval, "diffexpval.xdmf", "diffexpval.h5")
write(diffvar, "diffvarval.xdmf", "diffvarval.h5")
#catch
#	error("run the examples ASG_Sat_Mass_Transport and MC_Sat_Mass_Transport first")
#end