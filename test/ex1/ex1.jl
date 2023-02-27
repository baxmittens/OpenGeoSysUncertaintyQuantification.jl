include("../../src/OGSUQ.jl")

ogs_numeric_keyvals = ["value","reference_condition","slope", "reference_value","specific_body_force"]
function generateGenericStochasticOgsModell(prjfile::String,addfiles::String,simcall::String,postprocfile::Vector{String},outputpath="./Res",stochmethod=AdaptiveHierarchicalSparseGrid,n_local_workers=50,keywords=ogs_numeric_keyvals,sogsfile="StochasticOgs6Params.csv")
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

prjfile = "./project/disc_with_hole.prj"
addfiles = "./mesh"
simcall = "/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
postprocfile