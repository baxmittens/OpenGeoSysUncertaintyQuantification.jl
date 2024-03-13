function scalar_sobolindex_from_field_result(ogsuq::OGSUQMCSobol, sobolvars, totalvariance, xdmf::XDMF3File)
	modeldef = ogs6_modeldef(ogsuq)
	integrated_sobolvars = map(x->integrate_result(x,xdmf,modeldef), sobolvars)
	integrated_totalvariance = integrate_result(totalvariance,xdmf,modeldef)
	inds_sorted = sortperm(integrated_sobolvars, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuq)
	sobol_inds = integrated_sobolvars./integrated_totalvariance
	sobol_inds ./= sum(sobol_inds)
	for ind in inds_sorted
		push!(retvec, (ind, format_ogs_path(stoch_params[ind].path), sobol_inds[ind]))
	end
	return retvec
end

function scalar_sobolindex_from_multifield_result(ogsuq::OGSUQMCSobol, sobolvars, field::Int, totalvariance, xdmf::XDMF3File)
	modeldef = ogs6_modeldef(ogsuq)
	integrated_sobolvars = map(x->integrate_result(x[field],xdmf,modeldef), sobolvars)
	integrated_totalvariance = integrate_result(totalvariance[field],xdmf,modeldef)
	inds_sorted = sortperm(integrated_sobolvars, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuq)
	sobol_inds = integrated_sobolvars./integrated_totalvariance
	sobol_inds ./= sum(sobol_inds)
	for ind in inds_sorted
		push!(retvec, (ind, format_ogs_path(stoch_params[ind].path), sobol_inds[ind]))
	end
	return retvec
end

function scalar_sobolindex_from_multifield_result(ogsuqmc::OGSUQMCSobol, totsobolvars, fields::AbstractVector{Int}, varval, expval, xdmf::XDMF3File)
	modeldef = ogs6_modeldef(ogsuqmc)
	integrated_sobolvars = map(field->map(x->integrate_result(x[field],xdmf,modeldef), totsobolvars), fields)
	integrated_totalvariances = map(field->integrate_result(varval[field],xdmf,modeldef), fields)
	integrated_expvals = map(field->integrate_result(expval[field],xdmf,modeldef), fields)
	@assert all(map(field->all(map(x->x>=0.0, integrated_sobolvars[field])),1:length(integrated_totalvariances))) "negative sobolvars detected, use total sobol variances."
	coeff_of_var = map((x,y)->sqrt(x)/y, integrated_totalvariances, integrated_expvals)
	sobol_inds = map((x,y)->x/y, integrated_sobolvars, integrated_totalvariances).*coeff_of_var
	sobol_inds_scaled = map(x->sum(x), zip(sobol_inds...))/sum(coeff_of_var)
	sobol_inds_scaled ./= sum(sobol_inds_scaled)
	inds_sorted = sortperm(sobol_inds_scaled, rev=true)
	retvec = Vector{Tuple{Int,String,Float64}}()
	stoch_params = stoch_parameters(ogsuqmc)
	for ind in inds_sorted
		push!(retvec, (ind, format_ogs_path(stoch_params[ind].path), sobol_inds_scaled[ind]))
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

```julia
expval, varval, sobolvars, totsobolvars = start!(ogsuqmcsobl)
```

Assumes each index in `sobolvars` is a field result (i.e.
```julia
res["temperature_interpolated"][:,some_timestep]::Vector{Float64}
``` 
)

The result are written in the 0-th time slice of the [`XDMF3File`](https://github.com/baxmittens/XDMFFileHandler.jl/blob/38025866e4beb81eabc967904872dc7b27505c26/src/XDMFFileHandler.jl#L83).

# Arguments

- `ogsuqmc::`[`OGSUQMCSobol`](@ref) : Instance of [`OGSUQMCSobol`](@ref).
- `sobolvars` : Result of [`start!`](@ref)(ogsuqmcsobl::[`OGSUQMCSobol`](@ref)).
- `fieldname::String` : Fieldname, e.g. "temperature".
- `varval` : Global variance of stochastic state space defined in 
- `retval_proto` : Prototype for result type (only known after first OGS6 call, i.g. `DistributedSparseGrids.scaling_weight(first(asg))`)
"""
function write_sobol_field_result_to_XDMF(ogsuqmc::OGSUQMCSobol, sobolvars, fieldname::String, varval, expval, xdmf_proto_path::String)
	modeldef = ogs6_modeldef(ogsuqmc)
	stoch_params = stoch_parameters(ogsuqmc)
	xdmf = XDMF3File(xdmf_proto_path)
	add_scalar_field!(xdmf, expval, "0000_Expected Value", modeldef)
	add_scalar_field!(xdmf, varval, "0001_Variance", modeldef)
	ranking = scalar_sobolindex_from_field_result(ogsuqmc, sobolvars, varval, xdmf)
	trimpath(p) = replace(p, "@"=>"_", ","=>"_", " "=>"", "="=>"_")
	for (ind, path, val) in ranking
		_num = cfmt("%03i" , i )
		add_scalar_field!(xdmf, sobolvars[ind], _num*"_SobolVar_"*trimpath(path), modeldef)
		add_scalar_field!(xdmf, sobolvars[ind]./varval, "SobolInd_"*trimpath(path), modeldef)
	end
	return write(xdmf, fieldname*".xdmf", fieldname*"h5")
end

function write_sobol_multifield_result_to_XDMF(ogsuqmc::OGSUQMCSobol, sobolvars, field::Int, fieldname::String, varval, expval, xdmf_proto_path::String)
	modeldef = ogs6_modeldef(ogsuqmc)
	stoch_params = stoch_parameters(ogsuqmc)
	xdmf = XDMF3File(xdmf_proto_path)
	add_scalar_field!(xdmf, expval[field], "0000_Expected Value", modeldef)
	add_scalar_field!(xdmf, varval[field], "0001_Variance", modeldef)
	ranking = scalar_sobolindex_from_multifield_result(ogsuqmc, sobolvars, field, varval, xdmf)
	trimpath(p) = replace(p, "@"=>"_", ","=>"_", " "=>"", "="=>"_")
	for (i,(ind, path, val)) in enumerate(ranking)
		_num = cfmt("%03i" , i )
		add_scalar_field!(xdmf, sobolvars[ind][field], _num*"0_SobolVar_"*trimpath(path), modeldef)
		add_scalar_field!(xdmf, sobolvars[ind][field]./varval[field], _num*"1_SobolInd_"*trimpath(path), modeldef)
	end
	return write(xdmf, fieldname*".xdmf", fieldname*".h5") 
end