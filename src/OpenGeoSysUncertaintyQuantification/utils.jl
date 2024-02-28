
ogs_numeric_keyvals = ["value","reference_condition","slope", "reference_value","specific_body_force","values"]
function generatePossibleStochasticParameters(projectfile::String, file::String="./PossibleStochasticParameters.xml", keywords::Vector{String}=ogs_numeric_keyvals)
	modeldef = read(Ogs6ModelDef,projectfile)
	stochparams = Vector{StochasticOGS6Parameter}()
	pathes = Vector{String}()
	for keyword in keywords
		getAllPathesbyTag!(pathes,modeldef.xmlroot,keyword)
	end
	#writeXML(Julia2XML(pathes), file)
	write(file, Julia2XML(pathes))
	return pathes
end

function loadStochasticParameters(file::String="./PossibleStochasticParameters.xml")
	pathes = XML2Julia(read(XMLFile, file))
	return pathes
end

function createUserFiles(outfile::String, sogsfile::String, templatefile::String)
	f = open(templatefile)
	str = read(f,String)
	close(f)
	str = replace(str, "_ogsp_placeholder_"=>"$(sogsfile)")
	f = open(outfile, "w")
	write(f,str)
	close(f)
	println("Function template file written to $outfile")
end

function create_files_and_dirs(sogs::StochasticOGSModelParams)
	ogs6pp = sogs.ogsparams
	templatefile = joinpath(@__DIR__,"user_function_template.jl")
	#outfile = "./user_functions.jl"
	outfile = sogs.userfunctionfile
	if !isfile(outfile)
		createUserFiles(outfile,sogs.file,templatefile)
	end
	if !isdir(ogs6pp.outputpath)
		run(`mkdir $(ogs6pp.outputpath)`)
		println("Created Resultfolder $(ogs6pp.outputpath)")
	end
end

function generateStochasticOGSModell(
	projectfile::String,
	simcall::String,
	additionalprojecfilespath::String,
	postprocfile::Vector{String},
	stochpathes::Vector{String},
	outputpath="./Res",
	stochmethod=AdaptiveHierarchicalSparseGrid,
	n_local_workers=50,
	userfunctionfile="./user_functions.jl",
	sogsfile="StochasticOGSModelParams.xml"
	)

	modeldef = read(Ogs6ModelDef,projectfile)
	stochparams = Vector{StochasticOGS6Parameter}()
	#remote_workers = Tuple{String,Int}[]
	sort!(stochpathes)
	for path in stochpathes
		vals = getElementbyPath(modeldef, path)
		splitstr = split(vals.content[1])
		valspec = 1
		val = parse(Float64,splitstr[valspec])
		println(path)
		println(val)
		lb = val-abs(val/10)
		ub = val+abs(val/10)
		dist = Uniform(lb,ub)
		user_function = x->x
		push!(stochparams, StochasticOGS6Parameter(path,valspec,dist,lb,ub))
	end

	ogs6pp = OGS6ProjectParams(projectfile,simcall,additionalprojecfilespath,outputpath,postprocfile)
	#sogs = OGSUQParams(ogs6pp,stochparams,stochmethod,n_local_workers,remote_workers,sogsfile)
	sogs = StochasticOGSModelParams(ogs6pp,stochparams,stochmethod,n_local_workers,userfunctionfile,sogsfile)
	#writeXML(Julia2XML(sogs), sogsfile)
	write(sogsfile, Julia2XML(sogs))
	create_files_and_dirs(sogs)
	return sogs
end

function generateSampleMethodModel(::Type{AdaptiveHierarchicalSparseGrid}, sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	N = length(sogs.stochparams)
	CT = Float64
	RT = XDMF3File
	pointprobs = Int[1 for i = 1:N]
	init_lvl = N+1
	maxlvl = 20
	tol = 1e-2
	smparams = SparseGridParams(N,CT,RT,pointprobs,init_lvl,maxlvl,tol,anafile)
	#writeXML(Julia2XML(smparams), anafile)
	write(anafile, Julia2XML(smparams))
	return smparams
end

function generateSampleMethodModel(::Type{MonteCarlo}, sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	N = length(sogs.stochparams)
	CT = Float64
	RT = XDMF3File
	tol = 1e-2
	nshots = 100
	smparams = MonteCarloParams(N,CT,RT,nshots,tol,anafile)
	#writeXML(Julia2XML(smparams), anafile)
	write(anafile, Julia2XML(smparams))
	return smparams
end

function generateSampleMethodModel(::Type{MonteCarloSobol}, sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	N = length(sogs.stochparams)
	CT = Float64
	RT = XDMF3File
	tol = 1e-2
	nshots = 100
	smparams = MonteCarloSobolParams(N,CT,RT,nshots,tol,anafile)
	#writeXML(Julia2XML(smparams), anafile)
	write(anafile, Julia2XML(smparams))
	return smparams
end

function generateSampleMethodModel(::Type{MonteCarloMorris}, sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	N = length(sogs.stochparams)
	CT = Float64
	RT = XDMF3File
	tol = 1e-2
	nshots = 100
	lhs_sampling = false
	smparams = MonteCarloMorrisParams(N,CT,RT,nshots,lhs_sampling,anafile)
	#writeXML(Julia2XML(smparams), anafile)
	write(anafile, Julia2XML(smparams))
	return smparams
end

function generateSampleMethodModel(sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	return generateSampleMethodModel(sogs.samplemethod, sogs, anafile)
end

function generateSampleMethodModel(sogsfile::String, anafile="SampleMethodParams.xml")
	sogs = XML2Julia(read(XMLFile, sogsfile))
	return generateSampleMethodModel(sogs.samplemethod, sogs, anafile)
end

function lin_func(x,xmin,ymin,xmax,ymax)
	a = (ymax-ymin)/(xmax-xmin)
	b = ymax-a*xmax
	return a*x+b
end

function CPtoStoch(x,stoparam)
	return lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
end
function StochtoCP(x,stoparam)
	return lin_func(x, stoparam.lower_bound, -1.0, stoparam.upper_bound, 1.0)
end

function setStochasticParameter!(modeldef::Ogs6ModelDef, stoparam::StochasticOGS6Parameter, x, user_func::Function,cptostoch::Function=CPtoStoch)
	vals = getElementbyPath(modeldef, stoparam.path)
	splitstr = split(vals.content[1])
	splitstr[stoparam.valspec] = string(user_func(cptostoch(x,stoparam)))
	vals.content[1] = join(splitstr, " ")
	return nothing
end

function setStochasticParameters!(modeldef::Ogs6ModelDef, stoparams::Vector{StochasticOGS6Parameter}, x, user_funcs::Vector{Function},cptostoch::Function=CPtoStoch)
	foreach((_x,_y,_z)->setStochasticParameter!(modeldef, _y, _x, _z, cptostoch), x, stoparams, user_funcs)
	return nothing
end

function pdf(stoparam::StochasticOGS6Parameter, x::Float64)
	val = lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
	return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
	#return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))#*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
end

function pdf(stoparams::Vector{StochasticOGS6Parameter}, x)
	return foldl(*,map((x,y)->pdf(x,y),stoparams,x))
end

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
