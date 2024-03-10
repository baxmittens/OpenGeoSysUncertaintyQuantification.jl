import Base.show

function show(io::IO, mime::MIME"text/plain", stochparams::AbstractArray{StochasticOGS6Parameter})
	N = length(stochparams)
	title = "StochasticOGS6Parameters"
	header = ["#","Name", "Dist.", "lower_bound", "upper_bound", "valspec"]
	data = Matrix{Any}(undef, N, 6)
	for (i,stochparam) in enumerate(stochparams)
		data[i,1] = i
		data[i,2] = format_ogs_path(stochparam.path)
		data[i,3] = sprint(show, stochparam.dist)
		data[i,4] = stochparam.lower_bound
		data[i,5] = stochparam.upper_bound
		data[i,6] = stochparam.valspec
	end
	println(io)
	pretty_table(io, data; header=header, title=title)
end

function show(io::IO, ogs6proparams::OGS6ProjectParams)
	title = "OGS6ProjectParams"
	header = ["Paramemter","Value"]
	data = [
		"Project file" ogs6proparams.projectfile;
		"Simcall" ogs6proparams.simcall;
		"Add. files path" ogs6proparams.additionalprojecfilespath;
		"Output path" ogs6proparams.outputpath
		]
	postproc = [["Postproc file $i", ogs6proparams.postprocfiles[i]] for i = 1:length(ogs6proparams.postprocfiles)]
	println(io)
	pretty_table(io, vcat(data,permutedims(hcat(postproc...))); header=header, title=title)
end

function show(io::IO, ogsmodelparams::StochasticOGSModelParams)
	title = "StochasticOGSModelParams"
	header = ["Paramemter","Value"]
	data = [
		"Samplemethod" ogsmodelparams.samplemethod;
		"# local workers" ogsmodelparams.num_local_workers;
		"Userfunction file" ogsmodelparams.userfunctionfile;
		"file" ogsmodelparams.file
		]
	println(io)
	pretty_table(io, data; header=header, title=title)
	show(io, ogsmodelparams.ogsparams)
	show(io, "text/plain", ogsmodelparams.stochparams)
end

function show(io::IO, smp::SMP) where SMP<:SampleMethodParams
	_fieldnames = fieldnames(SMP)
	title = "$SMP"
	header = ["Paramemter","Value"]
	postproc = [[_fieldname, getfield(smp, _fieldname)] for _fieldname in _fieldnames]
	println(io)
	pretty_table(io, permutedims(hcat(postproc...)); header=header, title=title)
end

function show(io::IO, ogsuqparams::OGSUQParams)
	println(io)
	printstyled(io, "OGSUQParams"; color = :light_white)
	println(io)
	show(io, ogsuqparams.stochasticmodelparams)
	show(io, ogsuqparams.samplemethodparams)
end

function show(io::IO, ogsuq::OGSUQASG)
	println(io)
	printstyled(io, "OGSUQASG"; color = :light_white)
	println(io)
	show(io, ogsuq.ogsuqparams)
	println(io)
	show(io, ogsuq.asg)
end

function show(io::IO, ogsuq::T) where T<:AbstractOGSUQMonteCarlo
	println(io)
	printstyled(io, "$T"; color = :light_white)
	println(io)
	show(io, ogsuq.ogsuqparams)
	println(io)
	show(io, ogsuq.mc)
end