module OGSUQ

using XMLParser
import XMLParser: Julia2XML
using Distributed
using StaticArrays
using XDMFFileHandler
import AltInplaceOpsInterface: add!, minus!, pow!, max!, min!
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid,HierarchicalCollocationPoint, CollocationPoint, init, generate_next_level!, distributed_init_weights_inplace_ops!, AHSG, interpolate!, init_weights_inplace_ops!, integrate_inplace_ops, average_scaling_weight
import Distributions: Normal, Uniform, UnivariateDistribution, pdf, cdf
import VTUFileHandler: VTUFile
import Ogs6InputFileHandler: Ogs6ModelDef, getAllPathesbyTag!, rename!, getElementbyPath
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid
import LinearAlgebra: mul!
using DistributedMonteCarlo
import DistributedMonteCarlo: MonteCarlo

mutable struct OGS6ProjectParams
	projectfile::String
	simcall::String
	additionalprojecfilespath::String
	outputpath::String
	postprocfiles::Vector{String}
end

mutable struct StochasticOGS6Parameter
	path::String
	valspec::Int
	dist::UnivariateDistribution
	lower_bound::Float64
	upper_bound::Float64
end

mutable struct StochasticOGSModelParams
	ogsparams::OGS6ProjectParams
	stochparams::Vector{StochasticOGS6Parameter}
	samplemethod::Type
	num_local_workers::Int
	#remote_workers::Vector{Tuple{String,Int}}
	userfunctionfile::String
	file::String
end
filename(a::StochasticOGSModelParams) = a.file

abstract type SampleMethodParams end 
mutable struct SparseGridParams <: SampleMethodParams
	N::Int
	CT::Type
	RT::Type
	pointprobs::Vector{Int}
	init_lvl::Int
	maxlvl::Int
	tol::Float64
	file::String
end

mutable struct MonteCarloParams <: SampleMethodParams
	N::Int
	CT::Type
	RT::Type
	tol::Float64
	file::String
end
#mutable struct MCAnalysis{DIM,MCT,RT} <: StochasticAnalysis
#	mc::Union{Nothing,MonteCarlo{DIM,MCT,RT}}
#	nshots::Int
#	funfile::String
#	file::Union{Nothing,String}
#end
filename(a::SampleMethodParams) = a.file

mutable struct OGSUQParams
	stochasticmodelparams::StochasticOGSModelParams
	samplemethodparams::SampleMethodParams
end

function OGSUQParams(file_stochasticmodelparams::String, file_samplemethodparams::String)
	stochasticmodelparams = XML2Julia(read(XMLFile, file_stochasticmodelparams))
	samplemethodparams = XML2Julia(read(XMLFile, file_samplemethodparams))
	return OGSUQParams(stochasticmodelparams, samplemethodparams)
end

mutable struct OGSUQASG
	ogsuqparams::OGSUQParams
	asg::AdaptiveHierarchicalSparseGrid
end

mutable struct OGSUQMC
	params::OGSUQParams
end

include("./OGSUQ/utils.jl")

function init(::Type{AdaptiveHierarchicalSparseGrid}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	pointprobs = SVector(ogsuqparams.samplemethodparams.pointprobs...)
	asg = init(AdaptiveHierarchicalSparseGrid{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},pointprobs)
	return OGSUQASG(ogsuqparams, asg)
end

function init(ogsuqparams::OGSUQParams)
	create_files_and_dirs(ogsuqparams.stochasticmodelparams)
	actworker = nworkers()
	if actworker < ogsuqparams.stochasticmodelparams.num_local_workers-1
		naddprocs = ogsuqparams.stochasticmodelparams.num_local_workers-actworker
		@info "add $addprocs procs"
		addprocs(naddprocs)
	end
	@eval @everywhere include($(ogsuqparams.stochasticmodelparams.userfunctionfile))
	return init(ogsuqparams.stochasticmodelparams.samplemethod, ogsuqparams)
end

function scalarwise_comparefct(rt::VTUFile,tolrt,mintol)
	nfields = length(tolrt.data.interp_data)
	maxtols = map(i->max(maximum(tolrt.data.interp_data[i].dat),mintol),1:nfields) 
	allsmall = true
	for (maxtol,rtdat) in zip(maxtols,rt.data.interp_data)
		allsmall *= all(rtdat.dat .<= maxtol)
	end
	return !allsmall
end

function scalarwise_comparefct(rt::XDMF3File,tolrt,mintol)
	nfields = length(tolrt.idata.fields)
	maxtols = map(i->max(maximum(tolrt.idata.fields[i].dat),mintol),1:nfields) 
	allsmall = true
	for (maxtol,rtdat) in zip(maxtols,rt.idata.fields)
		allsmall *= all(rtdat.dat .<= maxtol)
	end
	return !allsmall
end

function scalarwise_comparefct(rt::XDMFData,tolrt,mintol)
	nfields = length(tolrt.fields)
	maxtols = map(i->max(maximum(tolrt.fields[i].dat),mintol),1:nfields) 
	allsmall = true
	for (maxtol,rtdat) in zip(maxtols,rt.fields)
		allsmall *= all(rtdat.dat .<= maxtol)
	end
	return !allsmall
end

function start!(ogsuqasg::OGSUQASG)
	asg = ogsuqasg.asg
	samplemethodparams = ogsuqasg.ogsuqparams.samplemethodparams
	init_lvl = samplemethodparams.init_lvl
	cpts = collect(asg)
	for i = 1:init_lvl
		append!(cpts,generate_next_level!(asg))
	end
	worker_ids = workers()
	@time distributed_init_weights_inplace_ops!(asg, cpts, Main.fun, worker_ids)
	tol =  samplemethodparams.tol
	maxlvl =  samplemethodparams.maxlvl
	tolrt = average_scaling_weight(asg, init_lvl) * tol
	comparefct(rt) = scalarwise_comparefct(rt,tolrt,tol)
	while true
  		cpts = generate_next_level!(asg, comparefct, maxlvl)
    	if isempty(cpts)
    		break
  		end
  		distributed_init_weights_inplace_ops!(asg, collect(cpts), Main.fun, worker_ids)
	end
end

function exp_val_func(x,ID,ogsuqasg::OGSUQASG,retval_proto::RT) where {RT}
	ret = similar(retval_proto)
	interpolate!(ret,ogsuqasg.asg, x)
	#mul!(ret,pdf(ogsuqasg.ogsuqparams.stochasticmodelparams.stochparams, x))
	return ret*pdf(ogsuqasg.ogsuqparams.stochasticmodelparams.stochparams, x)
end

function 𝔼(ogsuqasg::OGSUQASG)
	retval_proto = deepcopy(first(ogsuqasg.asg).scaling_weight)
	_exp_val_func(x,ID) = exp_val_func(x,ID,ogsuqasg,retval_proto)
	asg = ASG(ogsuqasg, _exp_val_func)
	return integrate_inplace_ops(asg),asg
end

function 𝔼(sogs) 
	return 𝔼(sogs.analysis,sogs) 
end

function var_func(x,ID,ogsuqasg::OGSUQASG, exp_val::RT) where {RT}
	stochparams = ogsuqasg.ogsuqparams.stochasticmodelparams.stochparams
	asg = ogsuqasg.asg
	ret = similar(exp_val)
	interpolate!(ret,asg,x)
	minus!(ret,exp_val)
	pow!(ret,2.0)
	mul!(ret,pdf(stochparams, x))
	#return ((ret-exp_val)^2)*pdf(stochparams, x)
	return ret
end

function var(ogsuqasg::OGSUQASG,exp_val::RT) where {RT}
	_var_func(x,ID) = var_func(x,ID,ogsuqasg,exp_val)
	asg = ASG(ogsuqasg, _var_func)
	return integrate_inplace_ops(asg),asg
end

export OGS6ProjectParams, StochasticOGS6Parameter, StochasticOGSModelParams, SampleMethodParams, SparseGridParams, 
	OGSUQParams, generatePossibleStochasticParameters, generateStochasticOGSModell, generateSampleMethodModel, loadStochasticParameters, 
	OGSUQASG, AdaptiveHierarchicalSparseGrid, Normal, Uniform, Ogs6ModelDef, getAllPathesbyTag!, VTUFile, rename!, AHSG, 
	setStochasticParameters!, lin_func, CPtoStoch, pdf, getElementbyPath, XDMF3File, XDMFData, MonteCarlo

end # module