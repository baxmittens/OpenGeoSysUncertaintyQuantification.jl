
"""
	dependend_tensor_parameter!(
		modeldef::Ogs6ModelDef, 
		stoparam::String, 
		master_ind::Int, 
		slave_ind::Int, 
		depfunc
	)

Helper function to model a dependency of entries of a tensor parmeter such as the permeability tensor k.
Uses OGS6 Pathes for parameter indentification (see [Ogs6InputfileHandler.getAllPathesbyTag](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L43) and [Ogs6InputFileHandler.getElementbyPath](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L51)).

# Arguments
- `modeldef::Ogs6ModelDef`: OSG6 Model Definition
- `stoparam::String`: OGS6 Path to parameter
- `master_ind::Int`: master index
- `slave_ind::Int`: slave index
- `depfunc`: dependency function

Example:

```julia
dependend_tensor_parameter!(
	modeldef, 
	path_to_permeability, 
	1,
	3, 
	x->0.5*x
)
```

The above example sets the third entry of the permeability tensor to half of the value of the first entry.
"""
function dependend_tensor_parameter!(modeldef::Ogs6ModelDef, stoparam::String, master_ind::Int, slave_ind::Int, depfunc)
	vals = getElementbyPath(modeldef, stoparam.path)
	splitstr = split(vals.content[1])
	val = parse(Float64,splitstr[master_ind])
	splitstr[slave_ind] = string(depfunc(val))
	vals.content[1] = join(splitstr, " ")
	return nothing
end


"""
	dependend_parameter!(
		modeldef::Ogs6ModelDef, 
		masterstoparam::String, 
		slavestoparam::String, 
		master_ind::Int, 
		slave_ind::Int, 
		depfunc
	)

Helper function to model a dependency of two OGS6 parameter.
Uses OGS6 Pathes for parameter indentification (see [Ogs6InputfileHandler.getAllPathesbyTag](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L43) and [Ogs6InputFileHandler.getElementbyPath](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/4f54995b12cd9d4396c1dcb2a78654c21af55e4c/src/Ogs6InputFileHandler/utils.jl#L51)).


# Arguments
- `modeldef::Ogs6ModelDef`: OSG6 Model Definition
- `masterstoparam::String`: OGS6 Path to master parameter
- `slavestoparam::String`: OGS6 Path to slave parameter
- `master_ind::Int`: master index
- `slave_ind::Int`: slave index
- `depfunc`: dependency function

Example:

```julia
dependend_tensor_parameter!(
	modeldef, 
	path_to_permeability_id1, 
	path_to_permeability_id2, 
	1, 
	1, 
	x->x
)
```

The above example couples two permeabilites of different material layers.
"""
function dependend_parameter!(modeldef::Ogs6ModelDef, masterstoparam::String, slavestoparam::String, master_ind::Int, slave_ind::Int, depfunc)
	master_vals = getElementbyPath(modeldef, masterstoparam.path)
	slave_vals = getElementbyPath(modeldef, slavestoparam.path)
	master_splitstr = split(master_vals.content[1])
	master_val = parse(Float64,master_splitstr[master_ind])
	slave_splitstr = split(slave_vals.content[1])
	slave_splitstr[slave_ind] = string(depfunc(master_val))
	slave_vals.content[1] = join(slave_splitstr, " ")
	return nothing
end

"""
	setStochasticParameter!(
		modeldef::Ogs6ModelDef, 
		stoparam::StochasticOGS6Parameter, 
		x, 
		user_func::Function,
		cptostoch::Function=CPtoStoch
	)

Replaces a stochastic parameter at `x` in the `modeldef`. Applies the user_func for addiational transformation (e.g. x->exp(x) in case of a lognormal distribution).

# Arguments
- `modeldef::`[`Ogs6ModelDef`] : OGS6 model definition.
- `stoparam::`[`StochasticOGS6Parameter`](@ref) : stochastic ogs parameter.
- `x::Float64` : sample point between -1 and 1. Gets transformed by cptostoch.
- `user_func::Function` : User function for additional transformation.
- `cptostoch::Function` : Transformation from [-1,1]  to [`stoparam.lower_bound`, `stoparam.upper_bound`].
"""
function setStochasticParameter!(modeldef::Ogs6ModelDef, stoparam::StochasticOGS6Parameter, x, user_func::Function,cptostoch::Function=CPtoStoch)
	vals = getElementbyPath(modeldef, stoparam.path)
	splitstr = split(vals.content[1])
	splitstr[stoparam.valspec] = string(user_func(cptostoch(x,stoparam)))
	vals.content[1] = join(splitstr, " ")
	return nothing
end

"""
	setStochasticParameters!(
		modeldef::Ogs6ModelDef, 
		stoparams::Vector{StochasticOGS6Parameter}, 
		x, 
		user_funcs::Vector{Function},
		cptostoch::Function=CPtoStoch
	)

Replaces all stochastic parameter at `x` in the `modeldef`. Applies all user_func for addiational transformation (e.g. x->exp(x) in case of a lognormal distribution).

# Arguments
- `modeldef::`[`Ogs6ModelDef`] : OGS6 model definition.
- `stoparam::`[`StochasticOGS6Parameter`](@ref) : stochastic ogs parameter.
- `x::Vector{Float64}` : sample point in the stochastic state space. Gets transformed by cptostoch.
- `user_funcs::Vector{Function}` : User function for additional transformation.
- `cptostoch::Function` : Transformation from [-1,1]  to [`stoparam.lower_bound`, `stoparam.upper_bound`].
"""
function setStochasticParameters!(modeldef::Ogs6ModelDef, stoparams::Vector{StochasticOGS6Parameter}, x, user_funcs::Vector{Function},cptostoch::Function=CPtoStoch)
	foreach((_x,_y,_z)->setStochasticParameter!(modeldef, _y, _x, _z, cptostoch), x, stoparams, user_funcs)
	return nothing
end