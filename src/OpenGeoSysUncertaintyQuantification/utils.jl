
ogs_numeric_keyvals = ["value", "reference_condition","slope", "reference_value", "specific_body_force", "values"]

"""
	generatePossibleStochasticParameters(
		projectfile::String,
		file::String="./PossibleStochasticParameters.xml",
		keywords::Vector{String}=ogs_numeric_keyvals
		)

Helper function for initial setup of a stochastic project. Scans an existing OGS6 projectfile (.prj) for keywords indicating numeric values usable as stochastic input parameter.
Returns a Vector of Strings with OGS6 pathes.
Uses OGS6 Pathes for parameter indentification (see [Ogs6InputfileHandler.getAllPathesbyTag](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L43) and [Ogs6InputFileHandler.getElementbyPath](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L51)).
Outputs an XML file written by [`XMLParser.Julia2XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).	

# Arguments
- `projectfile::String`: Path to OGS6 project file (e.g. ./path/to/project.prj)
- `file::String`: Path of output XML file which gets written by this function.
- `keywords::Vector{String}`: List of [`keywords`](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl/blob/6faab955f69da653e568b61eeb8890040001e7e6/src/OpenGeoSysUncertaintyQuantification/utils.jl#L2).
"""
function generatePossibleStochasticParameters(
	projectfile::String, 
	file::String="./StochasticParameters.xml", 
	keywords::Vector{String}=ogs_numeric_keyvals
	)

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

"""
	writeStochasticParameters(file::String="./PossibleStochasticParameters.xml")

Writes an XML file containing OGS6 pathes by [`XMLParser.XML2Julia`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L108).

# Arguments
- `pathes::Vector{String}`: Pathes to write.
- `file::String`: Path of XML file with OGS6 pathes.
"""
function writeStochasticParameters(pathes::Vector{String}, file::String="./StochasticParameters.xml")
	return write(file, Julia2XML(pathes))
end

"""
	write(sogs::StochasticOGSModelParams)

Writes an XML file containing OGS6 pathes by [`XMLParser.XML2Julia`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L108) to `sogs.file`.

# Arguments
- `sogs::StochasticOGSModelParams`: Stochastic OGS model.
"""
function Base.write(sogs::StochasticOGSModelParams)
	return write(sogs.file, Julia2XML(sogs))
end

"""
	write(file::String="./PossibleStochasticParameters.xml")

Writes an XML file containing OGS6 pathes by [`XMLParser.XML2Julia`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L108) to `sogs.file`.

# Arguments
- `sogs::SampleMethodParams`: Sample method parameters
"""
function Base.write(sogs::SampleMethodParams)
	return write(sogs.file, Julia2XML(sogs))
end

"""
	loadStochasticParameters(file::String="./PossibleStochasticParameters.xml")

Loads an XML file containing OGS6 pathes by [`XMLParser.XML2Julia`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L108).

# Arguments
- `file::String`: Path of XML file with OGS6 pathes.
"""
function loadStochasticParameters(file::String="./StochasticParameters.xml")
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

"""
	generateStochasticOGSModell(
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

Helper function for the generation of a stochastic OSG6 model. 
Writes the userfunction.jl file. 
Writes the stochastic model to an XML file by [`XMLParser.Julia2XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).

# Arguments
- `projectfile::String`: Path to OGS6 project file (e.g. ./path/to/project.prj)
- `simcall::String` : Path to the OGS6 binary (e.g. `path/to/ogs/bin/ogs`).
- `additionalprojecfilespath::String` : Path to the folder with additional project files (meshes & scripts) which gets copied to each realization folder.
- `postprocfiles::Vector{String}` : Array of OGS6 postprocessing results containing either vtu files (readable by [`VTUFileHandler.VTUFile`](https://baxmittens.github.io/VTUFileHandler.jl/dev/lib/lib/#VTUFileHandler.VTUFile)) or xdmf files (readable by [`XDMFFileHandler.XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L25)).
- `stochpathes::Vector{String}` : Vector with OGS6 pathes (see [Ogs6InputfileHandler.getAllPathesbyTag](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L43) and [Ogs6InputFileHandler.getElementbyPath](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L51)).  
- `outputpath::String` : Output path (e.g. path/to/Res/).
- `stochmethod::Type` : Either [`DistributedSparseGrids.AdaptiveHierarchicalSparseGrid`](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/lib/lib/#DistributedSparseGrids.AdaptiveHierarchicalSparseGrid), [`DistributedMonteCarlo.MonteCarlo`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L16C16-L16C26),  [`DistributedMonteCarlo.MonteCarloSobol`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L161), or [`DistributedMonteCarlo.MonteCarloMorris`](https://github.com/baxmittens/DistributedMonteCarlo.jl/blob/c2a2ecdff052adaeb783f32543c815b88df0fc57/src/DistributedMonteCarlo.jl#L538). 
- `n_local_workers::Int` : Number of local workers to be added by [`Distributed.addprocs`](https://docs.julialang.org/en/v1/stdlib/Distributed/#Distributed.addprocs).
- `userfunctionfile::String` : path to userfunction file. 
- `file::String` : path to file to write the StochasticOGSModelParams as XML file (e.g. path/to/stochmodel.xml).
"""
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

"""
	generateSampleMethodModel(sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")

Helper function for the creation of the [`SampleMethodParams`](@ref) data structure.
Writes the output file with [`XMLParser.Julia2XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).

# Arguments
- `sogs::`[`StochasticOGSModelParams`](@ref) : Stochastic OGS model generated, e.g. with [`generateStochasticOGSModell`](@ref).
- `anafile::String` : Path to output XML.
"""
function generateSampleMethodModel(sogs::StochasticOGSModelParams, anafile="SampleMethodParams.xml")
	return generateSampleMethodModel(sogs.samplemethod, sogs, anafile)
end

"""
	generateSampleMethodModel(sogsfile::String, anafile="SampleMethodParams.xml")

Helper function for the creation of the [`SampleMethodParams`](@ref) data structure.
Writes the output file with [`XMLParser.Julia2XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35).

# Arguments
- `sogs::`[`StochasticOGSModelParams`](@ref) : Path to stochastic ogs xml model file (e.g. path/to/stochmodel.xml)
- `anafile::String` : Path to output XML.
"""
function generateSampleMethodModel(sogsfile::String, anafile="SampleMethodParams.xml")
	sogs = XML2Julia(read(XMLFile, sogsfile))
	return generateSampleMethodModel(sogs.samplemethod, sogs, anafile)
end

function lin_func(x,xmin,ymin,xmax,ymax)
	a = (ymax-ymin)/(xmax-xmin)
	b = ymax-a*xmax
	return a*x+b
end

"""
	CPtoStoch(x::T,stoparam::StochasticOGS6Parameter) where T<:Number

The stochastic state space is always a [-1,1]^n cube. All stochastic parameters get mapped onto this cube.
Accepts an x∈[-1,1] and returns a value x'∈[stoparam.lower_bound, stoparam.upper_bound].

# Arguments
- `x::T` : Value between -1 and 1.
- `stoparam::`[`StochasticOGS6Parameter`](@ref) : stochastic ogs parameter.
"""
function CPtoStoch(x::T,stoparam::StochasticOGS6Parameter) where T<:Number
	return lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
end

"""
	StochtoCP(x::T,stoparam::StochasticOGS6Parameter) where T<:Number

The stochastic state space is always a [-1,1]^n cube. All stochastic parameters get mapped onto this cube.
Accepts an x∈[stoparam.lower_bound, stoparam.upper_bound] and returns a value x'∈[-1,1].

# Arguments
- `x::T` : Value between stoparam.lower_bound and stoparam.upper_bound.
- `stoparam::`[`StochasticOGS6Parameter`](@ref) : stochastic ogs parameter.
"""
function StochtoCP(x::T,stoparam::StochasticOGS6Parameter) where T<:Number
	return lin_func(x, stoparam.lower_bound, -1.0, stoparam.upper_bound, 1.0)
end

function pdf(stoparam::StochasticOGS6Parameter, x::Float64)
	#Todo use CPtoStoch and truncated here and test.
	val = lin_func(x, -1.0, stoparam.lower_bound, 1.0, stoparam.upper_bound)
	return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
	#return pdf(stoparam.dist, val)/(cdf(stoparam.dist, stoparam.upper_bound)-cdf(stoparam.dist, stoparam.lower_bound))#*(0.5*abs(stoparam.upper_bound-stoparam.lower_bound))
end

function pdf(stoparams::Vector{StochasticOGS6Parameter}, x)
	return foldl(*,map((x,y)->pdf(x,y),stoparams,x))
end

function install_ogs()
	@warn "python version < 3.12 has to be installed for this to work"
	PATH = joinpath(splitpath(@__FILE__)[1:end-3]..., "test")
	installscript = joinpath(PATH, "install_ogs.sh")
	run(`bash $installscript $PATH`)
	return joinpath(PATH,"/ogspyvenv/bin/ogs")
end