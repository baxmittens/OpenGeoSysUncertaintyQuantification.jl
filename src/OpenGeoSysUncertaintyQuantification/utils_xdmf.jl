function integrate_nodal_result(field::Vector{Float64},xdmf::T,modeldef::Ogs6ModelDef) where T
	error("integrate_nodal_result not implemented for type $T")
end

function integrate_cell_result(field::Vector{Float64},xdmf::T,modeldef::Ogs6ModelDef) where T
	error("integrate_cell_result not implemented for type $T")
end

function integrate_nodal_result(field::Vector{Float64}, xdmf::XDMF3File, modeldef::Ogs6ModelDef)
	#only implemented for 2d results in XY plane
	@assert displacement_order(modeldef) == 2 "`integrate_result` only implemented for displacements of order 2."
	ws = [-0.5625, 0.520833333333333, 0.520833333333333, 0.520833333333333]
	ξs = [0.333333333333333 0.333333333333333; 0.2 0.6; 0.2 0.2; 0.6 0.2]
	geom = xdmf.udata["geometry"]
	topo = reshape(xdmf.udata["topology"],7,:)[2:end,:]
	nels = size(topo)[2] 
	val = 0.0
	for nel in 1:nels
		inds = topo[:,nel] .+ 1
		tmpval = 0.0
		for nip in 1:length(ws)
			w = ws[nip]
			ξ = ξs[nip,:]
			tmpval += (Tri6_shapeFun(ξ)'*field[inds])[1] * w
		end
		A = Tri3_area_XY_plane(geom[:,inds[1]], geom[:,inds[2]], geom[:,inds[3]])
		val += tmpval * A
	end
	return val
end

function integrate_cell_result(field::Vector{Float64}, xdmf::XDMF3File, modeldef::Ogs6ModelDef)
	@assert displacement_order(modeldef) == 2 "`integrate_result` only implemented for displacements of order 2."
	geom = xdmf.udata["geometry"]
	topo = reshape(xdmf.udata["topology"],7,:)[2:end,:]
	nels = size(topo)[2] 
	val = 0.0
	for nel in 1:nels
		inds = topo[:,nel] .+ 1
		A = Tri3_area_XY_plane(geom[:,inds[1]], geom[:,inds[2]], geom[:,inds[3]])
		val += field[nel] * A
	end
	return val
end

function integrate_area(xdmf::XDMF3File, modeldef::Ogs6ModelDef)
	#only implemented for 2d results in XY plane
	@assert displacement_order(modeldef) == 2 "`integrate_area` only implemented for displacements of order 2."
	geom = xdmf.udata["geometry"]
	topo = reshape(xdmf.udata["topology"], 7, :)[2:end, :]
	nels = size(topo)[2] 
	valA = 0.0
	for nel in 1:nels
		inds = topo[:,nel] .+ 1
		A = Tri3_area_XY_plane(geom[:,inds[1]], geom[:,inds[2]], geom[:,inds[3]])
		valA += A
	end
	return valA
end

function is_nodal(res::Vector{Float64},xdmf::XDMF3File)
	dim = length(res)
	geom = xdmf.udata["geometry"]
	nnodes = size(geom)[2]
	return dim==nnodes
end

function integrate_result(field::Vector{Float64}, xdmf::XDMF3File, modeldef::Ogs6ModelDef)
	if is_nodal(field, xdmf)
		return integrate_nodal_result(field, xdmf, modeldef)
	else
		return integrate_cell_result(field, xdmf, modeldef)
	end
end

function element_coords(pt,geom,topo)
	for i = 1:size(topo,2)
		inds = topo[2:end,i] .+ 1
		pintri3 = PointInTri3(pt, geom[:,inds[1]], geom[:,inds[2]], geom[:,inds[3]])
		if pintri3
			return inds, globalToLocalGuess(pt, geom[:, inds[1:3]])
		end
	end
	error("Point $pt not found in XDMF")
end