using XMLParser
using OGSUQ

stochmodelparams = XML2Julia(read(XMLElement, "_ogsp_placeholder_"))
stoparams = stochmodelparams.stochparams
ogsparams = stochmodelparams.ogsparams
modeldef = read(Ogs6ModelDef, ogsparams.projectfile)

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
		foreach(x->cp(joinpath(ogsparams.additionalprojecfilespath,x), joinpath(PATH,x)), copyfiles)
		setStochasticParameters!(modeldef, stoparams, x)
		write(md)
		return joinpath(PATH,name)
	end

function fun(x,ID, modeldef=modeldef, ogsparams=ogsparams, stoparams=stoparams)
	println(ID)
	if create_directories(ID, ogsparams)
		PATH = create(x,ID, modeldef, ogsparams, stoparams)
		println("ogs call @$x")
		run(pipeline(`$(ogsparams.simcall) -o $(joinpath(ogsparams.outputpath,ID)) $PATH`, joinpath(ogsparams.outputpath,ID,"out.txt")))
		println("ogs call finished")
	end
	res = VTUFile(joinpath(ogsparams.outputpath,ID,ogsparams.postprocfiles[end]))
	return res
end