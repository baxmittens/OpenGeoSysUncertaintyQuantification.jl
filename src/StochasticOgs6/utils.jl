
ogs_numeric_keyvals = ["value","reference_condition","slope", "reference_value"]
function generateGenericStochasticOgsModell(prjfile::String,simcall::String,addfiles::String,postprocfile::Vector{String},outputpath="./Res",stochmethod=AdaptiveHierarchicalSparseGrid,n_local_workers=50,keywords=ogs_numeric_keyvals,sogsfile="StochasticOgs6Params.csv")
	modeldef = read(Ogs6ModelDef,prjfile)
	stochparams = Vector{StochasticOgs6Parameter}()
	pathes = Vector{String}()
	num_local_workers = n_local_workers
	remote_workers = Tuple{String,Int}[]
	for keyword in keywords
		getAllPathesbyTag!(pathes,modeldef.xmlroot,keyword)
	end
	sort!(pathes)
	for path in pathes
		valspec = 1
		dist = Uniform(0,1)
		lb = -1
		ub = 1
		user_function = x->x
		push!(stochparams, StochasticOgs6Parameter(path,valspec,dist,lb,ub))
	end
	ogsp = Ogs6ProjectParams(prjfile,simcall,addfiles,outputpath,postprocfile)
	sogs = StochasticOgs6(ogsp,modeldef,stochparams,stochmethod,num_local_workers,remote_workers,nothing,nothing,sogsfile)
	write(sogs, sogsfile)
	if !isdir(ogsp.outputpath)
		run(`mkdir $(ogsp.outputpath)`)
		println("Created Resultfolder $(ogsp.outputpath)")
	end
	return sogs
end

function generateGenericStochasticAnalysis!(::Type{AHSG}, sogs::StochasticOgs6, anafile="StochasticAnalysisParams.csv")
	N = length(sogs.stochparams)
	CT = Float64
	RT = VTUFile
	CPType = CollocationPoint{N,CT}
	HCPType = HierarchicalCollocationPoint{N,CPType,RT}
	Maxp = 1
	init_lvl = 3
	maxlvl = 20
	nrefsteps = 4
	tol = 1e-2
	pointprobs = SVector{N,Int}([1 for i = 1:N])
	sogs.analysis = AHSGAnalysis{N,CT,RT}(nothing, pointprobs, Maxp, init_lvl, maxlvl, tol, "user_functions.jl", anafile)
	file = joinpath(@__DIR__,"distributed_function_template.jl")
	createFiles(sogs.analysis,sogs,file)
	write(sogs.analysis,anafile)
	return sogs.analysis
end

function generateGenericStochasticAnalysis!(::Type{MonteCarlo}, sogs::StochasticOgs6, anafile="StochasticAnalysisParams.csv")
	DIM = length(sogs.stochparams)
	nshots = 10000
	MCT = Float64
	RT = VTUFile
	sogs.analysis = MCAnalysis{DIM,MCT,RT}(nothing, nshots, "user_functions.jl", anafile)
	file = joinpath(@__DIR__,"distributed_function_template.jl")
	createFiles(sogs.analysis,sogs,file)
	write(sogs.analysis,anafile)
	return sogs.analysis
end

function generateGenericStochasticAnalysis!(sogs::StochasticOgs6)
	return generateGenericStochasticAnalysis!(sogs.stochmethod, sogs)
end

function lin_func(x,xmin,ymin,xmax,ymax)
	a = (ymax-ymin)/(xmax-xmin)
	b = ymax-a*xmax
	return a*x+b
end
function CPtoStoch(x,stoparam)
	return lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
end

#function CTtoStoParam(x,stoparam)
#	return lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
#end

function setStochasticParameter!(modeldef::Ogs6ModelDef, stoparam::StochasticOgs6Parameter, x, user_func::Function,cptostoch::Function=CPtoStoch)
	vals = getElementbyPath(modeldef, stoparam.path)
	splitstr = split(vals.content[1])
	splitstr[stoparam.valspec] = string(user_func(cptostoch(x,stoparam)))
	vals.content[1] = join(splitstr, " ")
	return nothing
end

function setStochasticParameters!(modeldef::Ogs6ModelDef, stoparams::Vector{StochasticOgs6Parameter}, x, user_funcs::Vector{Function},cptostoch::Function=CPtoStoch)
	foreach((_x,_y,_z)->setStochasticParameter!(modeldef, _y, _x, _z, cptostoch), x, stoparams, user_funcs)
	return nothing
end

function Distributions.pdf(stoparam::StochasticOgs6Parameter, x::Float64)
	val = lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
	return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
	#return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))#*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
end

function Distributions.pdf(stoparams::Vector{StochasticOgs6Parameter}, x)
	return foldl(*,map((x,y)->pdf(x,y),stoparams,x))
end

function ASG(ana::AHSGAnalysis{N, CT, RT}, _fun, tol=1e-4) where {N,CT,RT}
	asg = init(AHSG{N,HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}},ana.pointprobs)
	cpts = Set{HierarchicalCollocationPoint{N,CollocationPoint{N,CT},RT}}(collect(asg))
	for i = 1:5
		union!(cpts,generate_next_level!(asg))
	end
	@time init_weights_inplace_ops!(asg, collect(cpts), _fun)
	for i = 1:20
		println("adaptive ref step $i")
		# call generate_next_level! with tol=1e-5 and maxlevels=20
		cpts = generate_next_level!(asg, tol, 20)
		if isempty(cpts)
			break
		end
		init_weights_inplace_ops!(asg, collect(cpts), _fun)
		println("$(length(cpts)) new cpts")
	end
	return asg
end
