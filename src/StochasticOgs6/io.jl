
SIM_START_BLOCK =   ["#-----------------------------Simulation_Params-----------------------------#"]
SIM_END_BLOCK =     ["#--------------------------End_Simulation_Params----------------------------#"]
STOCH_START_BLOCK = ["#----------------------------Stochastic_Params----------------------------#"]
STOCH_SPEC_BLOCK =  ["Path" "value(dummy)" "valspec" "Distribution" "lower-bound" "upper-bound"]
STOCH_END_BLOCK =   ["#--------------------------End_Stochastic_Params----------------------------#"]

function Base.write(sogs::StochasticOgs6, file::String)
	if sogs.sogsfile != file
		sogs.sogsfile = file
		println("StochasticOsg6-file changed to $file")
	end
	io = open(file,"w")
	writedlm(io, SIM_START_BLOCK)
	writedlm(io, ["projectfile:" sogs.ogsparams.projectfile])
	writedlm(io, ["additionalprojecfilespath:" sogs.ogsparams.additionalprojecfilespath])
	writedlm(io, ["simcall:" sogs.ogsparams.simcall])
	writedlm(io, ["postprocfiles:" sogs.ogsparams.postprocfiles...])
	writedlm(io, ["outputpath:" sogs.ogsparams.outputpath])
	writedlm(io, ["stochmeth:" sogs.stochmethod])
	writedlm(io, ["num_local_workers:" sogs.num_local_workers])
	writedlm(io, ["remote_workers:" "$(sogs.remote_workers)"])
	writedlm(io, SIM_END_BLOCK)
	writedlm(io, STOCH_START_BLOCK)
	writedlm(io, STOCH_SPEC_BLOCK)
	for stochparam in sogs.stochparams
		xmlel = getElementbyPath(sogs.modeldef,stochparam.path)
		if typeof(xmlel.content[1]) != XMLElement
			writedlm(io, [stochparam.path map(x->replace(x,"\t"=>" "),xmlel.content) stochparam.valspec strip(string(stochparam.dist)) stochparam.lower_bound stochparam.upper_bound])
		end
	end
	writedlm(io, STOCH_END_BLOCK)
	close(io)
	println("StochasticOsg6-file written to $file")
end

dists = Dict{String,Any}("Uniform"=>Uniform, "Uniform{Float64}"=>Uniform{Float64}, "Normal"=>Normal, "Normal{Float64}"=>Normal{Float64}, "LogNormal{Float64}"=>LogNormal{Float64}) 
stochmechs = Dict{String,Any}("AdaptiveHierarchicalSparseGrid"=>AdaptiveHierarchicalSparseGrid, "MonteCarlo"=>MonteCarlo)

function distparser(str::String)
	call = dists[str[1:findfirst(x->x=='(',str)-1]]
	argstring = str[findfirst(x->x=='(',str)+1:findfirst(x->x==')',str)-1]
	argstring = replace(argstring,r"[a-dfz=,]+"=>" ")
	args = filter(!isempty,split(argstring," "))
	return call(map(x->parse(Float64,x),args)...)
end

function Base.read(::Type{Vector{StochasticOgs6Parameter}}, dlm::Matrix{Any} )
	stochparams=Vector{StochasticOgs6Parameter}()
	start_stoch_params = findfirst(map(x->x==STOCH_START_BLOCK[1],dlm[:,1]))+2
	stop_stoch_params = findfirst(map(x->x==STOCH_END_BLOCK[1],dlm[:,1]))-1
	for i = start_stoch_params:stop_stoch_params
		path = dlm[i,1]
		valspec = dlm[i,3]
		dist =  distparser(String(dlm[i,4]))
		lb = dlm[i,5]
		ub = dlm[i,6]
		#println("path ",path,"\n valspec ",valspec,"\n dist ",dist,"\n lb ",lb,"\n ub ",ub)
		push!(stochparams, StochasticOgs6Parameter(path,valspec,dist,lb,ub))
	end
	return stochparams
end

function Base.read(::Type{Vector{StochasticOgs6Parameter}}, file::String )
	dlm = readdlm(file,'\t')
	return read(Vector{StochasticOgs6Parameter}, dlm::Matrix{Any} )
end

function Base.read(::Type{Ogs6ProjectParams}, dlm::Matrix{Any})
	projectfile = dlm[2,2]
	additionalprojecfilespath = dlm[3,2]
	simcall = dlm[4,2]
	postprocfiles = filter(!isempty,dlm[5,2:end])
	outputpath = dlm[6,2]
	return Ogs6ProjectParams(projectfile,simcall,additionalprojecfilespath,outputpath,postprocfiles)
end


function Base.read(::Type{Ogs6ProjectParams}, file::String)
	dlm = readdlm(file,'\t')
	return read(Ogs6ProjectParams, dlm)
end

function Base.read(::Type{StochasticOgs6}, file::String)
	dlm = readdlm(file,'\t')
	stochmech = dlm[7,2]
	num_local_workers = dlm[8,2]
	remote_workers = eval(Meta.parse(dlm[9,2]))
	stochparams = read(Vector{StochasticOgs6Parameter}, dlm)
	#println(dlm)
	ogsp = read(Ogs6ProjectParams, dlm)
	if !isdir(ogsp.outputpath)
		run(`mkdir $(ogs.outputpath)`)
		println("Created Resultfolder $(ogs.outputpath)")
	end
	modeldef = read(Ogs6ModelDef, ogsp.projectfile)
	return StochasticOgs6(ogsp,modeldef,stochparams,stochmechs[stochmech],num_local_workers,remote_workers,nothing,nothing,file)
end

function Base.write(ana::AHSGAnalysis, file::String)
	if ana.anafile != file
		ana.anafile = file
		println("Analyse-file changed to $file")
	end
	io = open(file,"w")
	writedlm(io, SIM_START_BLOCK)
	writedlm(io, ["N:" numdim(ana)])
	writedlm(io, ["CollocationPointType:" CollocationType(ana)])
	writedlm(io, ["ReturnType:" ReturnType(ana)])
	writedlm(io, ["pointprobs:" ana.pointprobs...])
	writedlm(io, ["maxp:" ana.maxp])
	writedlm(io, ["init_lvl:" ana.init_lvl])
	writedlm(io, ["maxlvl:" ana.maxlvl])
	writedlm(io, ["tol:" ana.tol])
	writedlm(io, ["functiondir:" ana.funfile])
	writedlm(io, SIM_END_BLOCK)
	close(io)
	println("Analyse-file written to $file")
end

function Base.write(ana::MCAnalysis, file::String)
	if ana.anafile != file
		ana.anafile = file
		println("Analyse-file changed to $file")
	end
	io = open(file,"w")
	writedlm(io, SIM_START_BLOCK)
	writedlm(io, ["N:" numdim(ana)])
	writedlm(io, ["MCType:" MCType(ana)])
	writedlm(io, ["ReturnType:" ReturnType(ana)])
	writedlm(io, ["nshots:" ana.nshots])
	writedlm(io, ["functiondir:" ana.funfile])
	writedlm(io, SIM_END_BLOCK)
	close(io)
	println("Analyse-file written to $file")
end

function Base.read(::Type{MCAnalysis}, file::String)
	dlm = readdlm(file,'\t')
	DIM = dlm[2,2]
	MCT = eval(Meta.parse(dlm[3,2]))
	RT = eval(Meta.parse(dlm[4,2]))
	nshots = dlm[5,2]
	funfile = dlm[6,2]
	return MCAnalysis{DIM,MCT,RT}(nothing, nshots, funfile, file)
end

function Base.read(::Type{AHSGAnalysis}, file::String)
	dlm = readdlm(file,'\t')
	N = dlm[2,2]
	CT = eval(Meta.parse(dlm[3,2]))
	RT = eval(Meta.parse(dlm[4,2]))
	pointprobs = SVector{N,Int}(dlm[5,2:end])
	maxp = dlm[6,2]
	init_lvl = dlm[7,2]
	maxlvl = dlm[8,2]
	tol = dlm[9,2]
	funfile = dlm[10,2]
	return AHSGAnalysis{N,CT,RT}(nothing, pointprobs, maxp, init_lvl, maxlvl, tol, funfile, file)
end

function createFiles(ana::AHSGAnalysis{N,CT,RT}, sogs::StochasticOgs6, file::String) where {N,CT,RT}
	outfile = ana.funfile
	f = open(file)
	str = read(f,String)
	close(f)
	str = replace(str, "_ogsp_placeholder_"=>"$(sogs.sogsfile)")
	f = open(outfile, "w")
	write(f,str)
	close(f)
	println("Function template file written to $outfile")
end

function createFiles(ana::MCAnalysis{DIM,MCT,RT}, sogs::StochasticOgs6, file::String) where {DIM,MCT,RT}
	outfile = ana.funfile
	f = open(file)
	str = read(f,String)
	close(f)
	str = replace(str, "_ogsp_placeholder_"=>"$(sogs.sogsfile)")
	f = open(outfile, "w")
	write(f,str)
	close(f)
	println("Function template file written to $outfile")
end