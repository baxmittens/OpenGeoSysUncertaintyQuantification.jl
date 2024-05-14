using OpenGeoSysUncertaintyQuantification
import DelimitedFiles.writedlm

stochmodelparams = XML2Julia(read(XMLFile, "altered_StochasticOGSModelParams.xml"))
stoparams = stochmodelparams.stochparams
ogsparams = stochmodelparams.ogsparams
modeldef = read(Ogs6ModelDef, ogsparams.projectfile)

user_functions = Function[x->x for i = 1:length(stoparams)]

function create_directories(ID, ogsparams)
	PATH = joinpath(ogsparams.outputpath,ID)
	if all(map(x->isfile(joinpath(PATH,x)),ogsparams.postprocfiles))
		return false
	end
	if !ispath(PATH)
		mkdir(PATH)
	end	
	return true
end

function create(x, ID, modeldef, ogsparams, stoparams)
		md = deepcopy(modeldef)
		name = split(modeldef.name,"/")[end]
		PATH = joinpath(ogsparams.outputpath,ID)
		rename!(md, joinpath(PATH,name))
		copyfiles =  readdir(ogsparams.additionalprojecfilespath)
		foreach(x->cp(joinpath(ogsparams.additionalprojecfilespath,x), joinpath(PATH,x), force=true), copyfiles)
		setStochasticParameters!(md, stoparams, x, user_functions)
		write(md)
		top = Any[]
		for stoparam in stoparams
			vals = getElementbyPath(md, stoparam.path)
			push!(top,vals.content[1])
		end
		writedlm("./Res/"*ID*"/pars.txt",top)
		return joinpath(PATH,name)
	end

function fun(x,ID, modeldef=modeldef, ogsparams=ogsparams, stoparams=stoparams)
	println(ID)
	if create_directories(ID, ogsparams)
		PATH = create(x,ID, modeldef, ogsparams, stoparams)
		println("ogs call @$x")
		ENV["OMP_NUM_THREADS"] = 1
		run(pipeline(`$(ogsparams.simcall) -o $(joinpath(ogsparams.outputpath,ID)) $PATH`, joinpath(ogsparams.outputpath,ID,"out.txt")))
		println("ogs call finished")
	end
	res = XDMF3File(joinpath(ogsparams.outputpath,ID,ogsparams.postprocfiles[end]))
	return res.idata
end