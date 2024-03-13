import DistributedSparseGrids: AbstractCollocationPoint, AbstractHierarchicalCollocationPoint, AbstractHierarchicalSparseGrid
function ASG(::AbstractHierarchicalSparseGrid{N,HCP}, samplemethodparams::SparseGridParams, _fun) where {N,CT,RT,CP<:AbstractCollocationPoint{N,CT}, HCP<:AbstractHierarchicalCollocationPoint{N,CP,RT}}
	pointprobs = SVector(samplemethodparams.pointprobs...)
	asg = init(AHSG{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},pointprobs)
	cpts = Set{HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}}(collect(asg))
	for i = 1:samplemethodparams.init_lvl
		union!(cpts,generate_next_level!(asg))
	end
	@time init_weights_inplace_ops!(asg, collect(cpts), _fun)
	tol =  samplemethodparams.tol
	tolrt = average_scaling_weight(asg, samplemethodparams.init_lvl) * tol
	comparefct(rt) = scalarwise_comparefct(rt,tolrt,tol)
	for i = 1:samplemethodparams.maxlvl
		println("adaptive ref step $i")
		# call generate_next_level! with tol=1e-5 and maxlevels=20
		cpts = generate_next_level!(asg, comparefct, samplemethodparams.maxlvl)
		if isempty(cpts)
			break
		end
		init_weights_inplace_ops!(asg, collect(cpts), _fun)
		println("$(length(cpts)) new cpts")
	end
	return asg
end

function ASG(ogsuqasg::OGSUQASG, _fun)
	return ASG(ogsuqasg.asg, ogsuqasg.ogsuqparams.samplemethodparams, _fun)
end

using DistributedSparseGrids
import DistributedSparseGrids: refine!
using StaticArrays 

function getnextedgecpts(asg)
	nl = DistributedSparseGrids.numlevels(asg)
	cpts = filter(x->DistributedSparseGrids.level(x)==nl,collect(asg))
	if nl > 1
		filter!(cpt->all(cpt.cpt.coords .== 0.0 .|| cpt.cpt.coords .== 1.0 .|| cpt.cpt.coords .== -1.0), cpts)
	end
	return cpts
end

function refineedges!(asg, nlvl=3)
	for i = 1:nlvl-1
		cpts = getnextedgecpts(asg)
		map(x->refine!(asg,x),cpts)
	end
end

function gethyperedges(asg::DistributedSparseGrids.AdaptiveHierarchicalSparseGrid{N}) where N
	cpts = filter(x->DistributedSparseGrids.level(x)==N+1,collect(asg))
	nl = DistributedSparseGrids.numlevels(asg)
	if nl > 1
		filter!(cpt->all(cpt.cpt.coords .== 1.0 .|| cpt.cpt.coords .== -1.0), cpts)
	end
	return cpts
end

function start_asg_mc_sampling!(MC::MonteCarlo, fun)
	#Threads.@threads for i = 1:MC.n
	vals = Vector{typeof(fun(MC.rndF()))}(undef,MC.n)
	for i = 1:MC.n
		#@info "$i/$(MC.n) Monte Carlo Shot"	
		shot = MC.shots[i]
		ξs = shot.coords
		res = fun(ξs)
		vals[i] = res
		if mod(i,10_000) == 0
			println(i)
		end
	end
	return vals
end

"""
	sample_postproc_fun(asg, x, inds, ξs, retval_proto)

A sample postprocessing function for [`empirical_cdf`](@ref).

```julia
	# copy result prototype here so that the sparse grid can interpolate without allocations
	ret = deepcopy(retval_proto) 
	# interpolate value from sparse grid
	DistributedSparseGrids.interpolate!(ret,asg,x)
	# use the fourth result value (could also be something like ret["sigma"][inds,:,:])
	# and interpolate the value at the element coordinates by shape functions
	val = Tri6_shapeFun(ξs)'*ret[4][inds]
```

# Arguments

- `asg` : Addaptive sparse grid 
- `x` : sample point ∈ [-1,1]^n
- `inds` : Element indices
- `ξs` : Element coordinates
- `retval_proto` : Prototype for result type (only known after first OGS6 call, i.e. `DistributedSparseGrids.scaling_weight(first(asg))`)
"""
function sample_postproc_fun(asg, x, inds, ξs, retval_proto)
	# copy result prototype here so that the sparse grid can interpolate without allocations
	ret = deepcopy(retval_proto) 
	# interpolate value from sparse grid
	DistributedSparseGrids.interpolate!(ret,asg,x)
	# use the fourth result value (could also be something like ret["sigma"][inds,:,:])
	# and interpolate the value at the element coordinates by shape functions
	val = Tri6_shapeFun(ξs)'*ret[4][inds] 
	return val
end

function get_exp_and_quantiles(vals,quant_vals::AbstractVector{Float64})
	a = length(quant_vals)
	b = length(vals[1])
	qs = Matrix{Float64}(undef,a,b)
	emp_exp_val = zeros(Float64,b)
	for shot in vals
		emp_exp_val .+= shot
	end
	emp_exp_val ./= length(mc.shots)
	for i = 1:b
		qs_vals = Float64[]
		for shot in vals
			push!(qs_vals, shot[i])
		end
		_qs = quantile(qs_vals, quant_vals)
		qs[:,i] = _qs
	end
	return emp_exp_val, qs
end

function empirical_cdf_sampling(ogsuqasg::OGSUQASG, samplepoint::Vector{Float64}, MC_N::Int, postprocfun::F,  xdmf::XDMF3File) where {F<:Function}
	stochparams = stoch_parameters(ogsuqasg)
	modeldef = ogs6_modeldef(ogsuqasg)
	@assert displacement_order(modeldef) == 2 "`empirical_pdf` only implemented for displacements of order 2."
	geom = xdmf.udata["geometry"]
	topo = reshape(xdmf.udata["topology"],7,:)
	inds,ξs = element_coords(samplepoint,geom,topo) 
	N = length(stochparams)
	retval_proto = deepcopy(scaling_weight(first(ogsuqasg.asg)))
	randfct() = SVector{N,Float64}(map(i->StochtoCP(rand(truncated(stochparams[i].dist, lower=stochparams[i].lower_bound, upper=stochparams[i].upper_bound)), stochparams[i]),1:N)...)
	fun(x) = postprocfun(ogsuqasg.asg, x, inds, ξs, retval_proto)
	mc = MonteCarlo(Val(N),Float64,Vector{Float64}, MC_N, 0.0001, randfct)
	vals = start_asg_mc_sampling!(mc,fun)
	return mc,vals
end

"""
	empirical_cdf(
		ogsuqasg::OGSUQASG, 
		quant_vals::AbstractVector{Float64}, 
		samplepoint::Vector{Float64}, 
		MC_N::Int, 
		postprocfun::F,  
		xdmf::XDMF3File
		)


Computes the empirical cdf of an adaptive sparse grid surrogate model by Monte Carlo integration.
Assumes a two-dimensional OGS6 postprocessing result as xdmf file which lies in the XY-plane.
Returns the empirical expected value and the empirical output distribution.

# Arguments
- `ogsuqasg::`[`OGSUQASG`] : Stochastic OGS6 adaptive sparse grid model.
- `quant_vals::AbstractVector{Float64}` : Vector with quantiles. For each value the [quantile function](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.quantile) is evalulated.
- `samplepoint::Vector{Float64}` : Point with coordinates [x, y, 0.0].
- `MC_N::Int` : Number of Monte Carlo snapshots for integration of the empirical output.
- `postprocfun::F` : Postprocessing function, see [`sample_postproc_fun`](@ref).
- `xdmf::`[`XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L83) : An arbirtrary XDMF3File from the result folder is needed with the topology of the mesh.
"""
function empirical_cdf(ogsuqasg::OGSUQASG, quant_vals::AbstractVector{Float64}, samplepoint::Vector{Float64}, MC_N::Int, postprocfun::F,  xdmf::XDMF3File) where {F<:Function}
	mc,vals = empirical_cdf_sampling(ogsuqasg, samplepoint, MC_N, postprocfun,  xdmf)
	emp_exp_val,emp_qs = get_exp_and_quantiles(vals,quant_vals)
	return emp_exp_val,emp_qs
end

#import OpenGeoSysUncertaintyQuantification: displacement_order, element_coords, StochtoCP
#import XDMFFileHandler: PointInTri3, globalToLocalGuess, Tri6_shapeFun
#import Distributions: quantile
#samplepoint = [4016.38, -561.555, 0.]
##mc,vals = empirical_pdf(ogsuqasg, samplepoint, 10, sample_postproc_fun,  xdmf_proto)
#quant_vals = [0.005,0.05, 0.15, 0.25, 0.75 ,0.85, 0.95, 0.995]
##emp_exp_val, qs = get_exp_and_quantiles(vals,quant_vals)
#emp_exp_val,emp_qs = empirical_pdf(ogsuqasg, quant_vals, samplepoint, 10, sample_postproc_fun,  xdmf_proto)