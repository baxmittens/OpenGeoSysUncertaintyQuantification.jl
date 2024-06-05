using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!, integrate, interpolate
using Distributed

PATH = "./"
#PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
stochogsmodel_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
samplemethod_xml = joinpath(PATH, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(stochogsmodel_xml, samplemethod_xml)
ogsuqasg = init(ogsuqparams)
start!(ogsuqasg)
expval,asg_expval = 𝔼(ogsuqasg);
varval,asg_varval = variance(ogsuqasg, expval);

intval = integrate(asg_expval)

#sto1 = stoch_parameters(ogsuqasg)[1]
#sto2 = stoch_parameters(ogsuqasg)[2]
#using Distributions
#n = 1000
#a = [first(interpolate(asg_expval, [x,y])) for x in range(-1,1,length=n), y in range(-1,1,length=n)]
#b = [pdf(truncated(sto1.dist, sto1.lower_bound, sto1.upper_bound), x)*pdf(truncated(sto2.dist, sto2.lower_bound, sto2.upper_bound), y) for x in range(sto1.lower_bound,sto1.upper_bound,length=n), y in range(sto2.lower_bound,sto2.upper_bound,length=n)]

#println(sum(a)/n/n*2*2," ",sum(b)/n/n*(sto1.upper_bound-sto1.lower_bound)*(sto2.upper_bound-sto2.lower_bound))
println(integrate(asg_expval))
println(integrate(asg_varval))

ppfun = x->first(x)
using GLMakie
import DistributedSparseGridsPlotting: minval
f = Figure(size=(1000,800));
ax = Axis3(f[1,1]);
surface!(ax, ogsuqasg.asg, 20, ppfun);
scatter!(ax, ogsuqasg.asg, markersize=4, z_offset=minval(ogsuqasg.asg, ppfun));
f