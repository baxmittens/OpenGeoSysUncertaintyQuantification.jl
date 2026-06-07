using OpenGeoSysUncertaintyQuantification
import DelimitedFiles.writedlm
import XDMFFileHandler 
push!(XDMFFileHandler.interpolation_keywords, "Si")
push!(XDMFFileHandler.interpolation_keywords, "darcy_velocity")
push!(XDMFFileHandler.interpolation_keywords, "pressure")

stochmodelparams = XML2Julia(read(XMLFile, "/Users/maximilianbittens/.julia/dev/OpenGeoSysUncertaintyQuantification/test/Examples/OGSUQ/ASG_Sat_Mass_Transport/StochasticOGSModelParams.xml"))
stoparams = stochmodelparams.stochparams
ogsparams = stochmodelparams.ogsparams
modeldef = read(Ogs6ModelDef, ogsparams.projectfile)

user_functions = Function[x->x for i = 1:length(stoparams)]
user_functions[2] = x -> exp(x)

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
#./media/medium/@id/0/properties/property/?longitudinal_dispersivity/value
#./media/medium/@id/0/properties/property/?transversal_dispersivity/value
#./parameters/parameter/?decay/value
#path = "./parameters/parameter/?kappa1/values"
#valscpec = 4
function dependent_stoch_param!(modeldef, x, stoparam, path, valspec, user_func)
	vals = getElementbyPath(modeldef, path)
	splitstr = split(vals.content[1])
	splitstr[valspec] = string(user_func(CPtoStoch(x,stoparam)))
	vals.content[1] = join(splitstr, " ")
	return nothing
end

function create(x, ID, modeldef, ogsparams, stoparams)
		md = deepcopy(modeldef)
		name = split(modeldef.name,"/")[end]
		PATH = joinpath(ogsparams.outputpath,ID)
		rename!(md, joinpath(PATH,name))
		copyfiles =  readdir(ogsparams.additionalprojecfilespath)
		foreach(x->cp(joinpath(ogsparams.additionalprojecfilespath,x), joinpath(PATH,x), force=true), copyfiles)
		setStochasticParameters!(md, stoparams, x, user_functions)
		dependent_stoch_param!(md, x[1], stoparams[1], "./media/medium/@id/0/properties/property/?transversal_dispersivity/value", 1, user_functions[1])
		dependent_stoch_param!(md, x[2], stoparams[2], "./parameters/parameter/?kappa1/values", 4, user_functions[2])
		write(md)
		top = Any[]
		for stoparam in stoparams
			vals = getElementbyPath(md, stoparam.path)
			push!(top,vals.content[1])
		end
		writedlm(joinpath(PATH, "pars.txt"), top)
		writedlm(joinpath(PATH, "coords.txt"), x)
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
	return res
end