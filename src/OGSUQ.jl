module OGSUQ

using XMLParser
using Distributed
using StaticArrays
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid,HierarchicalCollocationPoint, CollocationPoint, init, generate_next_level!, distributed_init_weights_inplace_ops!
import Distributions: Normal, Uniform, UnivariateDistribution
import VTUFileHandler: VTUFile
import Ogs6InputFileHandler: Ogs6ModelDef, getAllPathesbyTag!
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid

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
	stochasticmodelparams = XML2Julia(read(XMLElement, file_stochasticmodelparams))
	samplemethodparams = XML2Julia(read(XMLElement, file_samplemethodparams))
	return OGSUQParams(stochasticmodelparams, samplemethodparams)
end

mutable struct OGSUQASG
	ogsuqparams::OGSUQParams
	asg::AdaptiveHierarchicalSparseGrid
end

#mutable struct OGSUQMC
#	params::OGSUQParams
#end

function init(::Type{AdaptiveHierarchicalSparseGrid}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	pointprobs = SVector(ogsuqparams.samplemethodparams.pointprobs...)
	asg = init(AdaptiveHierarchicalSparseGrid{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},pointprobs)
	return OGSUQASG(ogsuqparams, asg)
end

function init(ogsuqparams::OGSUQParams)
	actworker = nworkers()
	if actworker < ogsuqparams.stochasticmodelparams.num_local_workers
		naddprocs = ogsuqparams.stochasticmodelparams.num_local_workers-actworker
		@info "add $addprocs procs"
		addprocs(naddprocs)
	end
	@eval @everywhere include($(ogsuqparams.stochasticmodelparams.userfunctionfile))
	return init(ogsuqparams.stochasticmodelparams.samplemethod, ogsuqparams)
end

function start!(ogsuqasg::OGSUQASG)
	asg = ogsuqasg.asg
	cpts = collect(asg)
	for i = 1:sogs.analysis.init_lvl
		append!(cpts,generate_next_level!(asg))
	end
	#@time distributed_init_weights!(asg, cpts, fun, sogs.hpcparams.worker_ids)
	@time distributed_init_weights_inplace_ops!(asg, cpts, fun, sogs.hpcparams.worker_ids)
end

include("./OGSUQ/utils.jl")

export OGS6ProjectParams, StochasticOGS6Parameter, StochasticOGSModelParams, SampleMethodParams, SparseGridParams, OGSUQParams, generatePossibleStochasticParameters, generateStochasticOGSModell, generateSampleMethodModel, loadStochasticParameters, OGSUQASG, AdaptiveHierarchicalSparseGrid, Normal, Uniform, Ogs6ModelDef, getAllPathesbyTag!, VTUFile

end # module