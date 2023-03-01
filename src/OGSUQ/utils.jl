
ogs_numeric_keyvals = ["value","reference_condition","slope", "reference_value","specific_body_force","values"]
function generatePossibleStochasticParameters(projectfile::String, file::String="./PossibleStochasticParameters.xml", keywords::Vector{String}=ogs_numeric_keyvals)
	modeldef = read(Ogs6ModelDef,projectfile)
	stochparams = Vector{StochasticOGS6Parameter}()
	pathes = Vector{String}()
	for keyword in keywords
		getAllPathesbyTag!(pathes,modeldef.xmlroot,keyword)
	end
	writeXML(Julia2XML(pathes), file)
	return pathes
end

function loadStochasticParameters(file::String="./PossibleStochasticParameters.xml")
	pathes = XML2Julia(read(XMLElement, file))
	return pathes
end

function createUserFiles(outfile::String, sogsfile::String, templatefile::String) where {N,CT,RT}
	f = open(templatefile)
	str = read(f,String)
	close(f)
	str = replace(str, "_ogsp_placeholder_"=>"$(sogsfile)")
	f = open(outfile, "w")
	write(f,str)
	close(f)
	println("Function template file written to $outfile")
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
	keywords=ogs_numeric_keyvals,
	sogsfile="StochasticOGSModelParams.xml"
	)

	modeldef = read(Ogs6ModelDef,projectfile)
	stochparams = Vector{StochasticOGS6Parameter}()
	#remote_workers = Tuple{String,Int}[]
	sort!(stochpathes)
	for path in stochpathes
		valspec = 1
		dist = Uniform(0,1)
		lb = -1
		ub = 1
		user_function = x->x
		push!(stochparams, StochasticOGS6Parameter(path,valspec,dist,lb,ub))
	end

	templatefile = joinpath(@__DIR__,"user_function_template.jl")
	outfile = "./user_functions.jl"
	createUserFiles(outfile,sogs.file,templatefile)

	ogs6pp = OGS6ProjectParams(projectfile,simcall,additionalprojecfilespath,outputpath,postprocfile)
	#sogs = OGSUQParams(ogs6pp,stochparams,stochmethod,n_local_workers,remote_workers,sogsfile)
	sogs = StochasticOGSModelParams(ogs6pp,stochparams,stochmethod,n_local_workers,outfile,sogsfile)
	writeXML(Julia2XML(sogs), sogsfile)
	if !isdir(ogs6pp.outputpath)
		run(`mkdir $(ogs6pp.outputpath)`)
		println("Created Resultfolder $(ogs6pp.outputpath)")
	end
	return sogs
end

function generateSampleMethodModel(::Type{AdaptiveHierarchicalSparseGrid}, sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	N = length(sogs.stochparams)
	CT = Float64
	RT = VTUFile
	pointprobs = Int[1 for i = 1:N]
	init_lvl = N+1
	maxlvl = 20
	tol = 1e-2
	smparams = SparseGridParams(N,CT,RT,pointprobs,init_lvl,maxlvl,tol,anafile)
	writeXML(Julia2XML(smparams), anafile)
	return smparams
end

function generateSampleMethodModel(sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	return generateSampleMethodModel(sogs.samplemethod, sogs, anafile)
end

