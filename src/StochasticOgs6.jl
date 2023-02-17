using Distributions
using DelimitedFiles

include(joinpath("/home","bittens","workspace","OgsUQ","src","ParallelCompParams.jl"))
include(joinpath("/home","bittens","workspace","ogsfilehandling","src","Ogs6InputFileHandler.jl"))
#include(joinpath("/home","bittens","workspace","ogsfilehandling","src","VTUFileHandler.jl"))
import AltInplaceOperationInterface: add!, minus!, pow!, max!, min!
import LinearAlgebra: mul!, norm
using VTUFileHandler
import VTUFileHandler: VTUFile, PointInTri3, globalToLocalGuess, Tri6_shapeFun, Tri3_shapeFun, VTUDataField
#include(joinpath("/home","bittens","workspace","AdaptiveSparseGrids","src","AdaptiveSparseGrids.jl"))
using DistributedSparseGrids
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid
include(joinpath("/home","bittens","workspace","MonteCarloMethods","src","MonteCarlo.jl"))

function norm(dest::Vector{VTUDataField{Float64}})
	return max(map(x->norm(x.dat),dest)...)
end

function Base.fill!(dest::Vector{VTUDataField{Float64}}, x::Float64)
	for d in dest
		fill!(d,x)
	end
	return nothing
end

function Base.deepcopy(vtud::Vector{VTUDataField{Float64}})
	res = map(deepcopy,vtud)
	return res
end

function Base.similar(vtud::Vector{VTUDataField{Float64}})
	res = map(deepcopy,vtud)
	fill!(res,0.0)
	return res
end

function Base.zero(vtud::Vector{VTUDataField{Float64}})
	res = similar(vtud)
	fill!(res,0.0)
	return res 
end

function add!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}})
	for (d1,d2) in zip(zd1,zd2)
		add!(d1,d2)
	end
	return nothing
end

function minus!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}})
	for (d1,d2) in zip(zd1,zd2)
		minus!(d1,d2)
	end
	return nothing
end

function add!(zd1::Vector{VTUDataField{Float64}}, a::Number)
	for d1 in zd1
		add!(d1,a)
	end
	return nothing
end

function mul!(zd1::Vector{VTUDataField{Float64}}, c::Number)
	for d1 in zd1
		mul!(d1,c)
	end
	return nothing
end

function mul!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}}, zd3::Vector{VTUDataField{Float64}})
	for (d1,d2,d3) in zip(zd1,zd2,zd3)
		mul!(d1,d2,d3)
	end
	return nothing
end

function minus!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}}, fac::Float64)
	for (d1,d2) in zip(zd1,zd2)
		minus!(d1,d2,fac)
	end
	return nothing
end

function mul!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}}, fac::Float64)
	for (d1,d2) in zip(zd1,zd2)
		mul!(d1,d2,fac)
	end
	return nothing
end

function add!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}}, fac::Float64)
	for (d1,d2) in zip(zd1,zd2)
		add!(d1,d2,fac)
	end
	return nothing
end

function pow!(zd1::Vector{VTUDataField{Float64}}, a::Number)
	for d1 in zd1
		pow!(d1,a)
	end
	return nothing
end

function div!(zd1::Vector{VTUDataField{Float64}}, a::Number)
	for d1 in zd1
		div!(d1,a)
	end
	return nothing
end

function max!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}})
	for (d1,d2) in zip(zd1,zd2)
		max!(d1,d2)
	end
	return nothing
end

function min!(zd1::Vector{VTUDataField{Float64}}, zd2::Vector{VTUDataField{Float64}})
	for (d1,d2) in zip(zd1,zd2)
		max!(d1,d2)
	end
	return nothing
end

mutable struct StochasticOgs6Parameter
	path::String
	valspec::Int
	dist::UnivariateDistribution
	lower_bound::Float64
	upper_bound::Float64
end

abstract type StochasticAnalysis end 
mutable struct AHSGAnalysis{N,CT,RT} <: StochasticAnalysis
	asg::Union{Nothing,AHSG{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}}}
	pointprobs::SVector{N,Int}
	maxp::Int
	init_lvl::Int
	maxlvl::Int
	tol::Float64
	funfile::String
	anafile::Union{Nothing,String}
end
mutable struct MCAnalysis{DIM,MCT,RT} <: StochasticAnalysis
	mc::Union{Nothing,MonteCarlo{DIM,MCT,RT}}
	nshots::Int
	funfile::String
	anafile::Union{Nothing,String}
end
numdim(ana::MCAnalysis{DIM,MCT,RT}) where {DIM,MCT,RT} = DIM
numdim(ana::AHSGAnalysis{N,CT,RT}) where {N,CT,RT} = N
CollocationType(ana::AHSGAnalysis{N,CT,RT}) where {N,CT,RT} = CT
MCType(ana::MCAnalysis{DIM,MCT,RT}) where {DIM,MCT,RT} = MCT
ReturnType(ana::AHSGAnalysis{N,CT,RT}) where {N,CT,RT} = RT
ReturnType(ana::MCAnalysis{DIM,MCT,RT}) where {DIM,MCT,RT} = RT

mutable struct Ogs6ProjectParams
	projectfile::String
	simcall::String
	additionalprojecfilespath::String
	outputpath::String
	postprocfiles::Vector{String}
end

mutable struct StochasticOgs6
	ogsparams::Ogs6ProjectParams
	modeldef::Ogs6ModelDef
	stochparams::Vector{StochasticOgs6Parameter}
	stochmethod::Union{Type{AdaptiveHierarchicalSparseGrid},Type{MonteCarlo}}
	num_local_workers::Int
	remote_workers::Vector{Tuple{String,Int}}
	hpcparams::Union{Nothing,ParallelCompParams}
	analysis::Union{Nothing,StochasticAnalysis}
	sogsfile::Union{Nothing,String}
end

include(joinpath(".","StochasticOgs6","io.jl"))
include(joinpath(".","StochasticOgs6","utils.jl"))

function init!(ana::AHSGAnalysis{N,CT,RT},sogs::StochasticOgs6) where {N,CT,RT}
	@eval @everywhere include($(ana.funfile))
	ana.asg = init(AHSG{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},ana.pointprobs)
end

function MCRndFct(ana::MCAnalysis{DIM,MCT,RT},stochparams::Vector{StochasticOgs6Parameter}) where {DIM,MCT,RT}
	 return SVector{DIM,MCT}(rand(Truncated(stochparam.dist,stochparam.lower_bound, stochparam.upper_bound)) for stochparam in stochparams)
end

function init!(ana::MCAnalysis{DIM,MCT,RT},sogs::StochasticOgs6) where {DIM,MCT,RT}
	@eval @everywhere include($(ana.funfile))
	ana.mc = MonteCarlo(Val(DIM),MCT,RT, ana.nshots, 0.01, fun, ()->MCRndFct(sogs.analysis, sogs.stochparams)) 
end

function init!(sogs::StochasticOgs6)
	if sogs.analysis == nothing
		error("No analysis defined")
	end
	if sogs.hpcparams == nothing 
		sogs.hpcparams = ParallelCompParams(sogs.num_local_workers,sogs.remote_workers)
	end
	init!(sogs.analysis,sogs)
end

function start!(::AHSGAnalysis{N, CT, RT}, sogs) where {N,CT,RT}
	asg = sogs.analysis.asg
	cpts = collect(asg)
	for i = 1:sogs.analysis.init_lvl
		append!(cpts,generate_next_level!(asg))
	end
	#@time distributed_init_weights!(asg, cpts, fun, sogs.hpcparams.worker_ids)
	@time distributed_init_weights_inplace_ops!(asg, cpts, fun, sogs.hpcparams.worker_ids)
end

function start!(::Type{MonteCarlo}, sogs)
	start!(sogs.analysis.mc, sogs.hpcparams.worker_ids)
end

function start!(::Type{AdaptiveHierarchicalSparseGrid}, sogs)
	if !isdefined(sogs, :analysis)
		error("No analysis defined!")
	end
	start!(sogs.analysis, sogs)
end

function start!(sogs::StochasticOgs6)
	start!(sogs.stochmethod,sogs)
end

function exp_val_func(x,ID,sogs::StochasticOgs6,retval_proto)
	ret = similar(retval_proto)
	#ret = interpolate(ret,sogs.analysis.asg,x)
	interpolate!(ret,sogs.analysis.asg, x)
	mul!(ret,pdf(sogs.stochparams, x))
	#return ret*pdf(sogs.stochparams, x)
	return ret
end

function 𝔼(analysis::AHSGAnalysis{N, CT, RT},sogs::StochasticOgs6) where {N,CT,RT}
	retval_proto = deepcopy(first(sogs.analysis.asg).scaling_weight)
	_exp_val_func(x,ID) = exp_val_func(x,ID,sogs,retval_proto)
	asg = ASG(sogs.analysis, _exp_val_func)
	return integrate_inplace_ops(asg)
end

function 𝔼(sogs) 
	return 𝔼(sogs.analysis,sogs) 
end

function var_func(x,ID,stochparams::Vector{StochasticOgs6Parameter}, analysis::AHSGAnalysis{N, CT, RT}, exp_val::RT) where {N,CT,RT}
	ret = similar(exp_val)
	#fill!(ret,0.0)
	interpolate!(ret,analysis.asg,x)
	#ret = interpolate(analysis.asg,x)
	minus!(ret,exp_val)
	pow!(ret,2.0)
	mul!(ret,pdf(stochparams, x))
	#return ((ret-exp_val).^2)*pdf(stochparams, x)
	return ret
end

function var(analysis::AHSGAnalysis{N, CT, RT},sogs::StochasticOgs6,exp_val::RT) where {N,CT,RT}
	_var_func(x,ID) = var_func(x,ID,sogs.stochparams,sogs.analysis,exp_val)
	asg = ASG(sogs.analysis, _var_func)
	return integrate_inplace_ops(asg)
end

function var(sogs,exp_val)
	return var(sogs.analysis, sogs, exp_val)
end


