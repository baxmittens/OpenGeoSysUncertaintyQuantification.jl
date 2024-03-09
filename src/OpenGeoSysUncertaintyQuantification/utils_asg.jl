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

function start_mc_sampling!(MC::MonteCarlo, fun)
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