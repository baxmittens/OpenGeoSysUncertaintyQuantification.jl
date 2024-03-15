function scalar_sobolindex_from_field_result(ogsuq::OGSUQMCSobol, sobolvars, totalvariance, xdmf::XDMF3File, pathmapping::Union{Nothing,Dict{String,String}}=nothing)
	trimpath(p) = isnothing(pathmapping) ? format_ogs_path(p) : pathmapping[p]
	modeldef = ogs6_modeldef(ogsuq)
	integrated_sobolvars = map(x->integrate_result(x,xdmf,modeldef), sobolvars)
	integrated_totalvariance = integrate_result(totalvariance,xdmf,modeldef)
	inds_sorted = sortperm(integrated_sobolvars, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuq)
	sobol_inds = integrated_sobolvars./integrated_totalvariance
	sobol_inds ./= sum(sobol_inds)
	for ind in inds_sorted
		push!(retvec, (ind, trimpath(stoch_params[ind].path), sobol_inds[ind]))
	end
	return retvec
end

function scalar_sobolindex_from_multifield_result(ogsuq::OGSUQMCSobol, sobolvars, field::Int, totalvariance, xdmf::XDMF3File, pathmapping::Union{Nothing,Dict{String,String}}=nothing)
	trimpath(p) = isnothing(pathmapping) ? format_ogs_path(p) : pathmapping[p]
	modeldef = ogs6_modeldef(ogsuq)
	integrated_sobolvars = map(x->integrate_result(x[field],xdmf,modeldef), sobolvars)
	integrated_totalvariance = integrate_result(totalvariance[field],xdmf,modeldef)
	inds_sorted = sortperm(integrated_sobolvars, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuq)
	sobol_inds = integrated_sobolvars./integrated_totalvariance
	sobol_inds ./= sum(sobol_inds)
	for ind in inds_sorted
		push!(retvec, (ind, trimpath(stoch_params[ind].path), sobol_inds[ind]))
	end
	return retvec
end

function scalar_sobolindex_from_multifield_result(ogsuqmc::OGSUQMCSobol, totsobolvars, fields::AbstractVector{Int}, varval, expval, xdmf::XDMF3File, pathmapping::Union{Nothing,Dict{String,String}}=nothing)
	trimpath(p) = isnothing(pathmapping) ? format_ogs_path(p) : pathmapping[p]
	modeldef = ogs6_modeldef(ogsuqmc)
	integrated_totalvariances = map(field->integrate_result(varval[field],xdmf,modeldef), fields)
	area = integrate_area(xdmf, modeldef)
	coeff_of_var = map(field->integrate_result(sqrt.(varval[field])./expval[field],xdmf,modeldef), fields)./area
	sumcov = sum(coeff_of_var)
	sobol_inds = map(x->sum(map((field,cov,int_var)->integrate_result(x[field], xdmf, modeldef)*cov/int_var, fields,coeff_of_var,integrated_totalvariances))/sumcov, totsobolvars)
	sobol_inds_scaled = sobol_inds./sum(sobol_inds)
	inds_sorted = sortperm(sobol_inds_scaled, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuqmc)
	for ind in inds_sorted
		push!(retvec, (ind, trimpath(stoch_params[ind].path), sobol_inds_scaled[ind]))
	end
	return retvec
end

"""
	write_sobol_field_result_to_XDMF(
		ogsuqmc::OGSUQMCSobol, 
		sobolvars, 
		fieldname::String, 
		varval, 
		expval, 
		xdmf_proto_path::String
		)

Writes the result of [`start!`](@ref)(ogsuqmcsobl::[`OGSUQMCSobol`](@ref)) to an XMDF file.

Following outputs are provided by a Monte Carlo Sobol sampling:
```julia
expval, varval, sobolvars, totsobolvars = start!(ogsuqmcsobol)
```

Assumes each index in `sobolvars` is a single field result (i.e.
```julia
xdmf["temperature_interpolated"][:,some_timestep]::Vector{Float64}
``` 
)

The result are written in the 0-th time slice of the [`XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L83).

# Arguments

- `ogsuqmc::`[`OGSUQMCSobol`](@ref) : Instance of [`OGSUQMCSobol`](@ref).
- `sobolvars` : A result of [`start!`](@ref)(ogsuqmcsobl::[`OGSUQMCSobol`](@ref)).
- `fieldname::String` : Fieldname, e.g. "temperature".
- `varval` : Global variance of stochastic state space defined in `ogsuqmc`. 
- `expval` : Exptected value of stochastic state space defined in `ogsuqmc`. 
- `xdmf_proto_path::String` : Path to a xdmf file with similar topology like the result field.
"""
function write_sobol_field_result_to_XDMF(ogsuqmc::OGSUQMCSobol, sobolvars, fieldname::String, varval, expval, xdmf_proto_path::String, pathmapping::Union{Nothing,Dict{String,String}}=nothing)
	modeldef = ogs6_modeldef(ogsuqmc)
	stoch_params = stoch_parameters(ogsuqmc)
	xdmf = XDMF3File(xdmf_proto_path)
	add_scalar_field!(xdmf, expval, "0000_Expected Value", modeldef)
	add_scalar_field!(xdmf, varval, "0001_Variance", modeldef)
	ranking = scalar_sobolindex_from_field_result(ogsuqmc, sobolvars, varval, xdmf, pathmapping)
	trimpath(p) = replace(p, "@"=>"_", ","=>"_", " "=>"", "="=>"_")
	for (i,(ind, path, val)) in enumerate(ranking)
		_num = cfmt("%03i" , i )
		add_scalar_field!(xdmf, sobolvars[ind], _num*"_"*fieldname*"_0_SobolVar_"*trimpath(path), modeldef)
		copysb = deepcopy(sobolvars[ind])
		copysb[findall(x->x<0,copysb)] .= 0
		add_scalar_field!(xdmf, sqrt.(copysb), _num*"_"*fieldname*"_1_SobolSqrtVar_"*trimpath(path), modeldef)
		add_scalar_field!(xdmf, sobolvars[ind]./varval, _num*"_"*fieldname*"_2_SobolInd_"*trimpath(path), modeldef)
	end
	return write(xdmf, fieldname*".xdmf", fieldname*".h5")
end

"""
	write_sobol_multifield_result_to_XDMF(
		ogsuqmc::OGSUQMCSobol, 
		sobolvars,
		field, 
		fieldname::String, 
		varval, 
		expval, 
		xdmf_proto_path::String
		)

Writes the result of [`start!`](@ref)(ogsuqmcsobl::[`OGSUQMCSobol`](@ref)) to an XMDF file.

Following outputs are provided by a Monte Carlo Sobol sampling:
```julia
expval, varval, sobolvars, totsobolvars = start!(ogsuqmcsobol)
```

Assumes each index in `sobolvars` is a multifield result (i.e.
```julia
[xdmf["temperature_interpolated"][:,some_timestep]::Vector{Float64}, xdmf["pressure_interpolated"][:,some_timestep]::Vector{Float64}]
``` 
)

The result are written in the 0-th time slice of the [`XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L83).

# Arguments

- `ogsuqmc::`[`OGSUQMCSobol`](@ref) : Instance of [`OGSUQMCSobol`](@ref).
- `sobolvars` : A result of [`start!`](@ref)(ogsuqmcsobl::[`OGSUQMCSobol`](@ref)).
- `field::Any` : Field index to be postprocessed. Has to be compatible with `getindex`, i.e. `map(x->x[field] sobolvars)`.
- `fieldname::String` : Fieldname, e.g. "temperature".
- `varval` : Global variance of stochastic state space defined in `ogsuqmc`. 
- `xdmf_proto_path::String` : Path to a xdmf file with similar topology like the result field.
"""
function write_sobol_multifield_result_to_XDMF(ogsuqmc::OGSUQMCSobol, sobolvars, field, fieldname::String, varval, expval, xdmf_proto_path::String, pathmapping::Union{Nothing,Dict{String,String}}=nothing)
	modeldef = ogs6_modeldef(ogsuqmc)
	stoch_params = stoch_parameters(ogsuqmc)
	xdmf = XDMF3File(xdmf_proto_path)
	add_scalar_field!(xdmf, expval[field], "0000_"*fieldname*"_Expected Value", modeldef)
	add_scalar_field!(xdmf, varval[field], "0001_"*fieldname*"_Variance", modeldef)
	ranking = scalar_sobolindex_from_multifield_result(ogsuqmc, sobolvars, field, varval, xdmf, pathmapping)
	trimpath(p) = replace(p, "@"=>"_", ","=>"_", " "=>"", "="=>"_")
	for (i,(ind, path, val)) in enumerate(ranking)
		_num = cfmt("%03i" , i )
		add_scalar_field!(xdmf, sobolvars[ind][field], _num*"_"*fieldname*"_0_SobolVar_"*trimpath(path), modeldef)
		add_scalar_field!(xdmf, sobolvars[ind][field]./varval[field], _num*"_"*fieldname*"_1_SobolInd_"*trimpath(path), modeldef)
	end
	return write(xdmf, fieldname*".xdmf", fieldname*".h5") 
end

#import OpenGeoSysUncertaintyQuantification: write_sobol_multifield_result_to_XDMF, add_scalar_field!, scalar_sobolindex_from_multifield_result

function sobol_multifield_result_to_pgfplot(
		ogsuq::OGSUQMCSobol, 
		sobolvars, 
		field::Int,
		fieldname::String, 
		totalvariance, 
		xdmf::XDMF3File,
		n_entries_to_plot=10;
		width="0.95\\textwidth",
		height="0.2\\textheight",
		bar_width="0.0075\\textwidth"
		)
	ret = scalar_sobolindex_from_multifield_result(ogsuq, sobolvars, field, totalvariance, xdmf)
	n = min(n_entries_to_plot, length(ret))
	symcoords = map(x->replace(x[2],"_"=>" "), ret[1:n])
	coords = map(x->(replace(x[2],"_"=>" "),x[3]), ret[1:n])
	p1 = @pgf Axis(
		{
		ybar,
    		width=width,
    		height=height,
    		bar_width=bar_width,
    		legend_style=
    		{
    	        at = Coordinate(0.5, -0.775),
    	        anchor = "north",
    	        legend_columns = -1
    	    },
    		ylabel={""},
    		symbolic_x_coords=symcoords,
    		x_tick_label_style={rotate=45,anchor="east"},
    		xtick="data",
		},
		#Plot(Coordinates(dp)),
		Plot(Coordinates(coords)),
		Legend([fieldname])
	);
	buf = IOBuffer()
	print_tex(buf,p1)
	return String(take!(buf))
end

function sobol_multifield_result_to_pgfplot(
		ogsuq::OGSUQMCSobol, 
		sobolvars, 
		fields::AbstractVector{Int},
		field_names::Vector{String}, 
		totalvariance, 
		xdmf::XDMF3File,
		n_entries_to_plot=10;
		width="0.95\\textwidth",
		height="0.2\\textheight",
		bar_width="0.0075\\textwidth"
		)
	todict(x) = Dict(y[2]=>y[3] for y in x)
	rets = map(field->scalar_sobolindex_from_multifield_result(ogsuq, sobolvars, field, totalvariance, xdmf), fields)
	ret = scalar_sobolindex_from_multifield_result(ogsuq, sobolvars, fields, varval, expval, xdmf)
	retsdicts = map(todict, rets)
	retdict = todict(ret)
	n = min(n_entries_to_plot, length(ret))
	allcoords = Set{String}()
	foreach(x->foreach(y->push!(allcoords, y[2]), x[1:n]), rets)
	foreach(x->push!(allcoords, x[2]), ret[1:n])
	allcoords = collect(allcoords)
	ret = map(x->(x,retdict[x]), allcoords)
	sortinds = sortperm(ret,by=x->x[2],rev=true)
	_symcoords = map(x->replace(x,"_"=>""), allcoords[sortinds])
	coords = map(x->(replace(x,"_"=>""), retdict[x]), allcoords[sortinds])
	indv_coords = map(y->map(x->(replace(x,"_"=>""),y[x]), allcoords[sortinds]), retsdicts)
	p1 = @pgf Axis(
		{
		ybar,
    		width=width,
    		height=height,
    		bar_width=bar_width,
    		legend_style=
    		{
    	        at = Coordinate(0.5, -0.775),
    	        anchor = "north",
    	        legend_columns = -1
    	    },
    		ylabel={""},
    		symbolic_x_coords=_symcoords,
    		x_tick_label_style={rotate=45,anchor="east"},
    		xtick="data",
		},
		Plot(Coordinates(coords)),
		[Plot(Coordinates(c)) for c in indv_coords]...,
		Legend(["combined",field_names...])
	);
	buf = IOBuffer()
	print_tex(buf,p1)
	return String(take!(buf))
end