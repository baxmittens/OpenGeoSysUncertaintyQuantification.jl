#module OGSUQ

using XMLParser
using Distributions
import OgsInputFileHandler: Ogs6ModelDef

mutable struct OGS6ProjectParams
	projectfile::String
	simcall::String
	additionalprojecfilespath::String
	outputpath::String
	postprocfiles::Vector{String}
end

mutable struct StochasticOgs6Parameter
	path::String
	valspec::Int
	dist::UnivariateDistribution
	lower_bound::Float64
	upper_bound::Float64
end

mutable struct OGSOQ
	ogsparams::OGS6ProjectParams
	stochparams::Vector{StochasticOgs6Parameter}()
	stochmethod::String
	num_local_workers::Int
	remote_workers::Vector{Tuple{String,Int}}
end


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


a = Ogs6ProjectParams("test","testt","testtt","test",["testt,tatst"])
b = StochasticOgs6(a, Int, 1, [("1",2),("1",2)]) 

XML2Julia(Julia2XML(a))
XML2Julia(Julia2XML(b))



#end # module
