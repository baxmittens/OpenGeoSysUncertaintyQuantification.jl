module OpenGeoSysUncertaintyQuantification

using XMLParser
import XMLParser: Julia2XML, XMLFile, XML2Julia
using Distributed
using StaticArrays
using XDMFFileHandler
using XDMFFileHandler: Tri3_area_XY_plane, Tri6_shapeFun, add_cell_scalar_field!, add_nodal_scalar_field!
import AltInplaceOpsInterface: add!, minus!, pow!, max!, min!
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid,HierarchicalCollocationPoint, CollocationPoint, init, generate_next_level!, distributed_init_weights_inplace_ops!, AHSG, interpolate!, init_weights_inplace_ops!, integrate_inplace_ops, average_scaling_weight
import Distributions: Normal, Uniform, UnivariateDistribution, pdf, cdf, truncated, quantile
import VTUFileHandler: VTUFile
import Ogs6InputFileHandler: Ogs6ModelDef, getAllPathesbyTag!, rename!, getElementbyPath, displacement_order, format_ogs_path
import DistributedSparseGrids: AdaptiveHierarchicalSparseGrid, scaling_weight
import LinearAlgebra
import LinearAlgebra: mul!
import AltInplaceOpsInterface
using DistributedMonteCarlo
import DistributedMonteCarlo: MonteCarlo, distributed_𝔼, distributed_var
using Format
using PGFPlotsX
import PrettyTables: pretty_table

"""
	mutable struct OGS6ProjectParams


Container for OpenGeoSys 6 Parameters

# Fields

- `projectfile::String` : Path to the OGS6 project file (e.g. `path/to/project.prj`).
- `simcall::String` : Path to the OGS6 binary (e.g. `path/to/ogs/bin/ogs`).
- `additionalprojecfilespath::String` : Path to the folder with additional project files (meshes & scripts) which gets copied to each realization folder.
- `outputpath::String` : Path to Result folder (e.g. `path/to/stochprojectfolder/Res/`).
- `postprocfiles::Vector{String}` : Array of OGS6 postprocessing results containing either vtu files (readable by [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile)) or xdmf files (readable by [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25)).
"""
mutable struct OGS6ProjectParams
	projectfile::String
	simcall::String
	additionalprojecfilespath::String
	outputpath::String
	postprocfiles::Vector{String}
end

"""
	mutable struct StochasticOGS6Parameter

Container for the definition of a stochastic OGS6 parameter. For all distributions a lower and upper bound have to be provided. For [Distributions.Uniform](https://juliastats.org/Distributions.jl/latest/univariate/#Distributions.Uniform), this can be the interval \$[a,b]\$, for [Distributions.Normal](https://juliastats.org/Distributions.jl/latest/univariate/#Distributions.Normal), proper bounds have to be provided.

# Fields

- `path::String` : OGS6 path definition (see [Ogs6InputfileHandler.getAllPathesbyTag](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L43) and [Ogs6InputFileHandler.getElementbyPath](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L51)).
- `valspec::Int` : Value specifier (1 for scalar parameters, \$i\$ for \$i\$-th value of a tensor parameters written as a vector in OGS6 e.g. [\$a_1=a_{11}, a_2=a_{12}, a_3=a_{21}, a_4=a_{22}\$]).
- `dist::UnivariateDistribution` : Univariate distribution (see [`Distributions.UnivariateDistribution`](https://juliastats.org/Distributions.jl/stable/univariate/)).
- `lower_bound::Float64` : Lower bound for truncated distribution (see [`Distributions.truncated`](https://juliastats.org/Distributions.jl/latest/truncate/#Distributions.truncated)).
- `upper_bound::Float64` : Upper bound for truncated distribution (see [`Distributions.truncated`](https://juliastats.org/Distributions.jl/latest/truncate/#Distributions.truncated)).
"""
mutable struct StochasticOGS6Parameter
	path::String
	valspec::Int
	dist::UnivariateDistribution
	lower_bound::Float64
	upper_bound::Float64
end

"""
	mutable struct StochasticOGSModelParams

Container defining the stochastic OGS6 model.

# Fields

- `ogsparams::`[`OGS6ProjectParams`](@ref) : OGS 6 project parameters.
- `stochparams::Vector{`[`StochasticOGS6Parameter`](@ref)`}` : Vector defining the stochastic state space.
- `samplemethod::Type` : Either [DistributedSparseGrids.AdaptiveHierarchicalSparseGrid](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/lib/lib/#DistributedSparseGrids.AdaptiveHierarchicalSparseGrid), [DistributedMonteCarlo.MonteCarlo](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L16C16-L16C26),  [DistributedMonteCarlo.MonteCarloSobol](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L161), or [DistributedMonteCarlo.MonteCarloMorris](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L538).
- `num_local_workers::Int` : Number of local workers to be added by [Distributed.addprocs](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.addprocs).
- `userfunctionfile::String` : path to userfunction file. 
- `file::String` : path to file to write the StochasticOGSModelParams as XML-file by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).
"""
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

"""
	abstract type SampleMethodParams

Supertype for Sample method parameters.
"""
abstract type SampleMethodParams end

"""
	mutable struct SparseGridParams <: SampleMethodParams

Container for sparse grid paramters. For more information on the adaptive sparse grid, see the [documentation](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/).

# Fields

- `N::Int` : Dimension of the sparse grid, e.g. the stochastic state space.
- `CT::Type` : Type of the collocation points, normally `Float64`.
- `RT::Type` : Return type of the function [`fun`](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl/blob/5a8efaadb8b9de9e2380d759b2dd5e129550497a/src/OpenGeoSysUncertaintyQuantification/user_function_template.jl#L40) calling the OGS6 binary. Can be customized to `Float64`, `Vector{Float64}`, `Matrix{Float64}`,  [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25), [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile), or a custom data type which have to implement the [`AltInplaceOpsInterface`](https://github.com/baxmittens/AltInplaceOpsInterface.jl).
- `pointprobs::Vector{Int}` : Point set properties of the sparse grid, see [`DistributedSparseGrids.init`](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/lib/lib/#DistributedSparseGrids.init) and [`the point set example`](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/#Usage).
- `init_lvl::Int` : Number of initial hierarchical levels before adaptive refinement starts.
- `maxlvl::Int` : Number of additional hierarchical level after `init_lvl`.
- `tol::Float64` : tolerance for adaptive refinement.
- `file::String` : path to file to write the StochasticOGSModelParams as XML-file by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).
""" 
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

"""
	mutable struct MonteCarloParams <: SampleMethodParams

Container for Monte Carlo parameters.

# Fields

- `N::Int` : Dimension of the sparse grid, e.g. the stochastic state space.
- `CT::Type` : Type of the coordinates in the stochastic state space, normally `Float64`.
- `RT::Type` : Return type of the function [`fun`](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl/blob/5a8efaadb8b9de9e2380d759b2dd5e129550497a/src/OpenGeoSysUncertaintyQuantification/user_function_template.jl#L40) calling the OGS6 binary. Can be customized to `Float64`, `Vector{Float64}`, `Matrix{Float64}`,  [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25), [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile), or a custom data type which have to implement the [`AltInplaceOpsInterface`](https://github.com/baxmittens/AltInplaceOpsInterface.jl).
- `nshots::Int` : Number of Monte Carlo snapshots.
- `tol::Float64` : tolerance (not used at the moment).
- `file::String` : path to file to write the StochasticOGSModelParams as XML-file by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).
""" 
mutable struct MonteCarloParams <: SampleMethodParams
	N::Int
	CT::Type
	RT::Type
	nshots::Int
	tol::Float64
	file::String
end

"""
	mutable struct MonteCarloSobolParams <: SampleMethodParams

Container for Monte Carlo Sobol parameters.

# Fields

- `N::Int` : Dimension of the sparse grid, e.g. the stochastic state space.
- `CT::Type` : Type of the coordinates in the stochastic state space, normally `Float64`.
- `RT::Type` : Return type of the function [`fun`](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl/blob/5a8efaadb8b9de9e2380d759b2dd5e129550497a/src/OpenGeoSysUncertaintyQuantification/user_function_template.jl#L40) calling the OGS6 binary. Can be customized to `Float64`, `Vector{Float64}`, `Matrix{Float64}`,  [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25), [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile), or a custom data type which have to implement the [`AltInplaceOpsInterface`](https://github.com/baxmittens/AltInplaceOpsInterface.jl).
- `nshots::Int` : Number of Monte Carlo snapshots.
- `tol::Float64` : tolerance (not used at the moment).
- `file::String` : path to file to write the StochasticOGSModelParams as XML-file by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).
""" 
mutable struct MonteCarloSobolParams <: SampleMethodParams
	N::Int
	CT::Type
	RT::Type
	nshots::Int
	tol::Float64
	file::String
end

"""
	mutable struct MonteCarloMorrisParams

Container for Monte Carlo Morris parameters.

# Fields

- `N::Int` : Dimension of the sparse grid, e.g. the stochastic state space.
- `CT::Type` : Type of the coordinates in the stochastic state space, normally `Float64`.
- `RT::Type` : Return type of the function [`fun`](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl/blob/5a8efaadb8b9de9e2380d759b2dd5e129550497a/src/OpenGeoSysUncertaintyQuantification/user_function_template.jl#L40) calling the OGS6 binary. Can be customized to `Float64`, `Vector{Float64}`, `Matrix{Float64}`,  [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25), [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile), or a custom data type which have to implement the [`AltInplaceOpsInterface`](https://github.com/baxmittens/AltInplaceOpsInterface.jl).
- `ntrajectories::Int` : Number of trajectories. Each trajectories triggers \$N+1\$ deterministic OGS6 runs.
- `lhs_sampling::Bool` : If set to `true` a [optimized Latin Hypercube](https://mrurq.github.io/LatinHypercubeSampling.jl/stable/man/lhcoptim/#Optimised-Latin-Hypercube-Sampling-Plan) design is used instead of Monte Carlo integration. Functionality provided by the [`LatinHypercubeSampling.jl`](https://github.com/MrUrq/LatinHypercubeSampling.jl) package.
- `tol::Float64` : tolerance (not used at the moment).
- `file::String` : path to file to write the StochasticOGSModelParams as XML-file by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).
""" 
mutable struct MonteCarloMorrisParams <: SampleMethodParams
	N::Int
	CT::Type
	RT::Type
	ntrajectories::Int
	lhs_sampling::Bool
	file::String
end

filename(a::SampleMethodParams) = a.file

"""
	mutable struct OGSUQParams

Container for stochastic model parameters and sample method parameters.

# Fields

- `stochasticmodelparams::`[`StochasticOGSModelParams`](@ref) : stochastic model parameters.
- `samplemethodparams::`[`SampleMethodParams`](@ref) : sample method parameters: 

Can be instantiated by 
```julia
OGSUQParams(
	stochasticmodelparams::StochasticOGSModelParams, 
	samplemethodparams::SampleMethodParams
	)
``` 
or 
``` julia 
OGSUQParams(
	file_stochasticmodelparams::String, 
	file_samplemethodparams::String
	)
``` 
where `file_stochasticmodelparams` and `file_samplemethodparams` are pathes to xml files of [`StochasticOGSModelParams`](@ref) and [`SampleMethodParams`](@ref), respectively, written by [XMLParser.Julia2XML](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).

"""
mutable struct OGSUQParams
	stochasticmodelparams::StochasticOGSModelParams
	samplemethodparams::SampleMethodParams
end

function OGSUQParams(file_stochasticmodelparams::String, file_samplemethodparams::String)
	stochasticmodelparams = XML2Julia(read(XMLFile, file_stochasticmodelparams))
	samplemethodparams = XML2Julia(read(XMLFile, file_samplemethodparams))
	return OGSUQParams(stochasticmodelparams, samplemethodparams)
end

abstract type AbstractOGSUQ end 
abstract type AbstractOGSUQMonteCarlo <: AbstractOGSUQ end 
abstract type AbstractOGSUQSensitivity <: AbstractOGSUQMonteCarlo end 

"""
	mutable struct OGSUQASG

A stochastic OGS6 adaptive sparse grid model. The sparse grid is implemented by [`DistributedSparseGrids.jl`](https://github.com/baxmittens/DistributedSparseGrids.jl). For more information, see the [documentation](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/).
Instatiated by init function.

# Fields

- `ogsuqparams::`[`OGSUQParams`](@ref) : stochastic model and sample method parameters.
- `asg::`[`DistributedSparseGrids.AdaptiveHierarchicalSparseGrid`](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/lib/lib/#DistributedSparseGrids.AdaptiveHierarchicalSparseGrid) : instance of the adaptive sparse grid
"""
mutable struct OGSUQASG <: AbstractOGSUQ
	ogsuqparams::OGSUQParams
	asg::AdaptiveHierarchicalSparseGrid
end

"""
	mutable struct OGSUQMC

A stochastic OGS6 Monte Carlo model. The Monte Carlo Method is implemented by [`DistributedMonteCarlo.jl`](https://github.com/baxmittens/DistributedMonteCarlo.jl).
Instatiated by init function.

# Fields

- `ogsuqparams::`[`OGSUQParams`](@ref) : stochastic model and sample method parameters.
- `asg::`[`DistributedMonteCarlo.MonteCarlo`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L16) : instance of the Monte Carlo integrator.
"""
mutable struct OGSUQMC <: AbstractOGSUQMonteCarlo
	ogsuqparams::OGSUQParams
	mc::MonteCarlo
end

"""
	mutable struct OGSUQMCSobol

A stochastic OGS6 Sobol model. Integration of the Sobol indices implemented by [`DistributedMonteCarlo.jl`](https://github.com/baxmittens/DistributedMonteCarlo.jl).
Instatiated by init function.

# Fields

- `ogsuqparams::`[`OGSUQParams`](@ref) : stochastic model and sample method parameters.
- `mc::`[`DistributedMonteCarlo.MonteCarloSobol`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L161) : instance of the Monte Carlo Sobol integrator.
"""
mutable struct OGSUQMCSobol <: AbstractOGSUQSensitivity
	ogsuqparams::OGSUQParams
	mc::MonteCarloSobol
end


"""
	mutable struct OGSUQMCMorris

A Stochastic OGS6 Morris model. Integration of the Sobol indices implemented by [`DistributedMonteCarlo.jl`](https://github.com/baxmittens/DistributedMonteCarlo.jl).
Instatiated by init function.

# Fields

- `ogsuqparams::`[`OGSUQParams`](@ref) : stochastic model and sample method parameters.
- `mc::`[`DistributedMonteCarlo.MonteCarloMorris`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L538) : instance of the Monte Carlo Sobol integrator.
"""
mutable struct OGSUQMCMorris <: AbstractOGSUQSensitivity
	ogsuqparams::OGSUQParams
	mc::MonteCarloMorris
end

include("./OpenGeoSysUncertaintyQuantification/convienence.jl")
include("./OpenGeoSysUncertaintyQuantification/utils.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_xdmf.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_asg.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_sobol.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_user_file.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_integrity_criteria.jl")
include("./OpenGeoSysUncertaintyQuantification/utils_print.jl")

function init(::Type{AdaptiveHierarchicalSparseGrid}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	pointprobs = SVector(ogsuqparams.samplemethodparams.pointprobs...)
	asg = init(AdaptiveHierarchicalSparseGrid{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},pointprobs)
	return OGSUQASG(ogsuqparams, asg)
end

function init(::Type{MonteCarlo}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	nshots = ogsuqparams.samplemethodparams.nshots
	tol = ogsuqparams.samplemethodparams.tol
	#@todo include truncated for normal distribution
	randf() = map(x->StochtoCP(rand(ogsuqparams.stochasticmodelparams.stochparams[x].dist), ogsuqparams.stochasticmodelparams.stochparams[x]), 1:length(ogsuqparams.stochasticmodelparams.stochparams))
	mc = MonteCarlo(Val(N), CT, RT, nshots, tol, randf)
	return OGSUQMC(ogsuqparams, mc)
end

function init(::Type{MonteCarloSobol}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	nshots = ogsuqparams.samplemethodparams.nshots
	tol = ogsuqparams.samplemethodparams.tol
	pathA = joinpath(ogsuqparams.stochasticmodelparams.ogsparams.outputpath,"A")
	pathB = joinpath(ogsuqparams.stochasticmodelparams.ogsparams.outputpath,"B")
	pathA_B = joinpath(ogsuqparams.stochasticmodelparams.ogsparams.outputpath,"A_B")
	if !ispath(pathA)
		mkdir(pathA)
	end	
	if !ispath(pathB)
		mkdir(pathB)
	end	
	if !ispath(pathA_B)
		mkdir(pathA_B)
	end	
	#@todo include truncated for normal distribution
	randf() = map(x->StochtoCP(rand(ogsuqparams.stochasticmodelparams.stochparams[x].dist), ogsuqparams.stochasticmodelparams.stochparams[x]), 1:length(ogsuqparams.stochasticmodelparams.stochparams))
	mc = MonteCarloSobol(Val(N), CT, RT, nshots, tol, randf)
	return OGSUQMCSobol(ogsuqparams, mc)
end

function init(::Type{MonteCarloMorris}, ogsuqparams::OGSUQParams)
	N = ogsuqparams.samplemethodparams.N
	CT = ogsuqparams.samplemethodparams.CT
	RT = ogsuqparams.samplemethodparams.RT
	ntrajectories = ogsuqparams.samplemethodparams.ntrajectories
	lhs_sampling = ogsuqparams.samplemethodparams.lhs_sampling
	#@todo include truncated for normal distribution
	randf() = map(x->StochtoCP(rand(ogsuqparams.stochasticmodelparams.stochparams[x].dist), ogsuqparams.stochasticmodelparams.stochparams[x]), 1:length(ogsuqparams.stochasticmodelparams.stochparams))
	mc = MonteCarloMorris(Val(N), CT, RT, ntrajectories, randf)
	if lhs_sampling
		DistributedMonteCarlo.lhs_sampling!(mc) 
	end
	return OGSUQMCMorris(ogsuqparams, mc)
end

"""
	init(ogsuqparams::OGSUQParams)

Helper function to instantiate a stochastic OGS6 model. Return an object of type [`OGSUQASG`](@ref), [`OGSUQMC`](@ref), [`OGSUQMCSobol`](@ref), or [`OGSUQMCMorris`](@ref).

# Arguments
- `ogsuqparams::`[`OGSUQParams`](@ref): Stochastic model parameters.
"""
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

function scalarwise_comparefct(rt::Vector{Float64},tolrt,mintol)
	return any(abs.(rt) .> tolrt)
end

function scalarwise_comparefct(rt::Vector{Vector{Float64}},tolrt,mintol)
	return any(map((x,y)->any(abs.(x) .> y),rt,tolrt))
end

function start!(ogsuqasg::OGSUQASG, refinetohyperedges=false)
	asg = ogsuqasg.asg
	samplemethodparams = ogsuqasg.ogsuqparams.samplemethodparams
	init_lvl = samplemethodparams.init_lvl
	if refinetohyperedges
		hyperedgelevel = ogsuqasg.ogsuqparams.samplemethodparams.N+1
		refineedges!(asg, hyperedgelevel)
		cpts = collect(asg)
	else
		cpts = collect(asg)
		for i = 1:init_lvl
			append!(cpts,generate_next_level!(asg))
		end
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
	return nothing
end

function start!(ogsuqmc::OGSUQMC)
	DistributedMonteCarlo.load!(ogsuqmc.mc, ogsuqmc.ogsuqparams.stochasticmodelparams.ogsparams.outputpath)
	return nothing
end

function start!(ogsuqmc::OGSUQMCSobol)
	DistributedMonteCarlo.load!(ogsuqmc.mc, ogsuqmc.ogsuqparams.stochasticmodelparams.ogsparams.outputpath)
	return DistributedMonteCarlo.distributed_Sobol_Vars(ogsuqmc.mc, Main.fun, workers())
end

function start!(ogsuqmc::OGSUQMCMorris)
	DistributedMonteCarlo.load!(ogsuqmc.mc, ogsuqmc.ogsuqparams.stochasticmodelparams.ogsparams.outputpath)
	return DistributedMonteCarlo.distributed_means(ogsuqmc.mc, Main.fun, workers())
end

function exp_val_func(x,ID,ogsuqasg::OGSUQASG,retval_proto::RT) where {RT}
	ret = similar(retval_proto)
	interpolate!(ret,ogsuqasg.asg, x)
	#mul!(ret,pdf(ogsuqasg.ogsuqparams.stochasticmodelparams.stochparams, x))
	return ret*pdf(ogsuqasg.ogsuqparams.stochasticmodelparams.stochparams, x)
end

function 𝔼(ogsuqmc::OGSUQMC)
	worker_ids = workers()
	return distributed_𝔼(ogsuqmc.mc, Main.fun, worker_ids)
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

function variance(ogsuqasg::OGSUQASG,exp_val::RT) where {RT}
	_var_func(x,ID) = var_func(x,ID,ogsuqasg,exp_val)
	asg = ASG(ogsuqasg, _var_func)
	return integrate_inplace_ops(asg),asg
end

function variance(ogsuqmc::OGSUQMC, exp_val::RT) where {RT}
	return distributed_var(ogsuqmc.mc, Main.fun, exp_val, workers())
end

export OGS6ProjectParams, StochasticOGS6Parameter, StochasticOGSModelParams, SampleMethodParams, SparseGridParams, MonteCarloParams, MonteCarloSobolParams,
	OGSUQParams, generatePossibleStochasticParameters, generateStochasticOGSModell, generateSampleMethodModel, loadStochasticParameters, 
	OGSUQASG, OGSUQMC, OGSUQMCSobol, OGSUQMCMorris, AdaptiveHierarchicalSparseGrid, Normal, Uniform, Ogs6ModelDef, getAllPathesbyTag!, VTUFile, rename!, AHSG, 
	setStochasticParameters!, lin_func, CPtoStoch, pdf, getElementbyPath, XDMF3File, XDMFData, MonteCarlo, MonteCarloSobol, MonteCarloMorris, MonteCarloMorrisParams,
	variance, 𝔼, XMLFile, XML2Julia, init, start!, integrate_nodal_result, integrate_cell_result, integrate_area, integrate_result, ogs6_modeldef, stoch_parameters, scalar_sobolindex_from_multifield_result,
	scalar_sobolindex_from_field_result, scalar_sobolindex_from_multifield_result, write_sobol_multifield_result_to_XDMF, write_sobol_field_result_to_XDMF, dependend_tensor_parameter!, dependend_parameter!

end # module