
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
	x->0.5*x)
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
	x->x)
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