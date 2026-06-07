using OpenGeoSysUncertaintyQuantification
import DistributedSparseGrids: idstring, interpolate!
using Distributed

using DistributedSparseGrids
import DistributedSparseGrids: AbstractCollocationPoint, AbstractHierarchicalCollocationPoint, AbstractHierarchicalSparseGrid, numlevels, coord, pt_idx, i_multi, level, scaling_weight, fval
using Colors
import Colors: distinguishable_colors, RGB, N0f8, colormap
#using CairoMakie
using GLMakie
#using Makie

function Makie.scatter!(ax::AxisType, sg::SG; markersize=10, z_offset=hcpt->0.0) where {AxisType<:Makie.AbstractAxis, CT,CP<:AbstractCollocationPoint{2,CT},HCP<:AbstractHierarchicalCollocationPoint{2,CP},SG<:AbstractHierarchicalSparseGrid{2,HCP}}
	colors = cols = map(x->RGBA{Float64}(x.r,x.g,x.b,1.0), distinguishable_colors(numlevels(sg)+1, [RGB(1,1,1)])[2:end])
	nlevel = numlevels(sg)
	#traces = Vector{GenericTrace}(undef,nlevel)
	xvals = Vector{Vector{CT}}(undef,nlevel)
	yvals = Vector{Vector{CT}}(undef,nlevel)
	zvals = Vector{Vector{CT}}(undef,nlevel)
	#text = Vector{Vector{String}}(undef,nlevel)
	clr = Vector{Vector{RGB{N0f8}}}(undef,nlevel)
	isaxis2d = AxisType <: Axis ? true : (AxisType <: Axis3 ? false : error())
	for l = 1:nlevel
		xvals[l] = Vector{CT}()
		yvals[l] = Vector{CT}()
		zvals[l] = Vector{CT}()
		clr[l] = Vector{RGB{N0f8}}()
		#text[l] = Vector{String}()
	end
	for hcpt in sg
		l = level(hcpt)
		push!(xvals[l],coord(hcpt,1))
		push!(yvals[l],coord(hcpt,2))
		push!(zvals[l],z_offset(hcpt))
		#push!(zvals,interpolate(sg, [xvals[end], yvals[end]]))
		#push!(text[l],string(pt_idx(hcpt))*"^"*string(i_multi(hcpt)))
		push!(clr[l],colors[level(hcpt)])
	end
	for i = 1:nlevel
		mw = markersize-foldl((x,y)->x+2.0/(y),1:i)
		if isaxis2d
			Makie.scatter!(ax, xvals[i], yvals[i], markersize=mw, color=clr[i])
		else
			Makie.scatter!(ax, xvals[i], yvals[i], zvals[i], markersize=mw, color=clr[i])
		end
		#traces[i] = p = PlotlyJS.scatter(x=xvals[i], y=yvals[i], text=text[i], marker_color=clr[i], mode="markers",marker_size=mw,textposition="bottom center",name="level $i")
	end
	return nothing
end

function GLMakie.surface!(ax, asg::SG, npts = 20, postfun=x->x; kwargs...) where {CT,CP<:AbstractCollocationPoint{2,CT},HCP<:AbstractHierarchicalCollocationPoint{2,CP},SG<:AbstractHierarchicalSparseGrid{2,HCP}}
	xs = LinRange(-1.0, 1.0, npts)
	ys = LinRange(-1.0, 1.0, npts)
	rcp = first(asg)
	tmp = zero(scaling_weight(rcp))
	zs = [begin;
			interpolate!(tmp, asg, [x, y])
			postfun(tmp) 
		end
		for x in xs, y in ys]
	return GLMakie.surface!(ax, xs, ys, zs; kwargs...)
end

@everywhere begin
	import XDMFFileHandler 
	push!(XDMFFileHandler.interpolation_keywords, "Si")
	push!(XDMFFileHandler.interpolation_keywords, "darcy_velocity")
	push!(XDMFFileHandler.interpolation_keywords, "pressure")
end

PATH = "./"
#PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
stochogsmodel_xml = joinpath(PATH, "StochasticOGSModelParams.xml")
samplemethod_xml = joinpath(PATH, "SampleMethodParams.xml")

ogsuqparams = OGSUQParams(stochogsmodel_xml, samplemethod_xml)
ogsuqasg = init(ogsuqparams)

#ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.01
start!(ogsuqasg)

ogsuqasg.ogsuqparams.samplemethodparams.maxlvl = 15
ogsuqasg.ogsuqparams.samplemethodparams.tol = 0.0001
expval,asg_expval = 𝔼(ogsuqasg);
varval,asg_varval = variance(ogsuqasg, expval);

# XDMF cannot have '/' on name or h5 spec, therefore the path is the third argument 
# Base.write(xdmf3f::XDMF3File, name::String, newh5::String, path="./")
write(expval, "expval.xdmf", "expval.h5", PATH)
write(varval, "varval.xdmf", "varval.h5", PATH)

# import Pkg
# Pkg.add("PlotlyJS")
# Pkg.add("DistributedSparseGridsPlotting")

#using PlotlyJS
using DistributedSparseGridsPlotting
using GLMakie
using LinearAlgebra
using Statistics

ppfun(res) = norm(res["Si"][:,end])
ppfun(res) = mean(res["Si"][:,end])

f = Figure(size=(1600,800));
ax = Axis3(f[1, 1]);
Makie.scatter!(ax, ogsuqasg.asg, z_offset=hcpt->0.0)
surface!(ax, ogsuqasg.asg, 50, ppfun)
display(f)

f = Figure(size=(1600,800));
ax = Axis3(f[1, 1]);
Makie.scatter!(ax, asg_expval, z_offset=hcpt->0.0)
surface!(ax, asg_expval, 50, ppfun, colormap = (:viridis, 0.75))
display(f)

f = Figure(size=(1600,800));
ax = Axis3(f[1, 1]);
Makie.scatter!(ax, asg_varval, z_offset=hcpt->-0.025)
surface!(ax, asg_varval, 50, ppfun, colormap = (:viridis, 0.75))
display(f)

function totriangles(quadfaces)
	trifaces = Matrix{UInt64}(undef,size(quadfaces,1)*2,3)
	for i = 1:size(quadfaces,1)
		j = (i-1)*2+1
		trifaces[j,:] .= quadfaces[i,[1,2,3]]
		trifaces[j+1,:] .= quadfaces[i,[3,4,1]]
	end
	return trifaces
end

quadfaces = transpose(expval.udata["topology"][:,:,1].+1)
vertices = expval.udata["geometry"][1:2,:,1] 
trifaces = transpose(totriangles(quadfaces))
xx = map(x->x[1],eachcol(vertices))
yy = map(x->x[2],eachcol(vertices))

f = Figure(size=(1000,800));
ax1 = Axis(f[1, 1]);
#ax2 = Axis(f[1, 2]);
sl_x = Slider(f[2, 1], range = -1.0:0.1:1.0, startvalue = 0.0, update_while_dragging=true)
sl_y = Slider(f[3, 1], range = -1.0:0.1:1.0, startvalue = 0.0, update_while_dragging=true)
time = Slider(f[4, 1], range = 2:8, startvalue = 1.0, update_while_dragging=true)
interpres = map!(Observable{Any}(),sl_x.value,sl_y.value) do x,y
	interpolate(ogsuqasg.asg, [x,y])
end
vals = map!(Observable{Any}(),interpres,time.value) do res,t
	res["Si"][:,t]
end
valsp = map!(Observable{Any}(),interpres,time.value) do res,t
	res["pressure"][:,t]
end
arrx = map!(Observable{Any}(),interpres,time.value) do res,t
	#maxnorm = maximum(map(x->norm(x), eachcol(res["darcy_velocity"][:,:,t])))
	#res["darcy_velocity"][1,:,t]./maxnorm/10.0
	res["darcy_velocity"][1,:,t].*10.0
	#log10.(res["darcy_velocity"][1,:,t])
	
end
arry = map!(Observable{Any}(),interpres,time.value) do res,t
	#maxnorm = maximum(map(x->norm(x), eachcol(res["darcy_velocity"][:,:,t])))
	#res["darcy_velocity"][2,:,t]./maxnorm./10.0
	res["darcy_velocity"][2,:,t].*10.0
	#res["darcy_velocity"][2,:,t]
	#log10.(res["darcy_velocity"][2,:,t])
end
arrcol = map!(Observable{Any}(),interpres,time.value) do res,t
	map(x->norm(x), eachcol(res["darcy_velocity"][:,:,t]))
end

_cm1 = tricontourf!(ax1, xx, yy, vals, triangulation = trifaces)
#_cm1 = tricontourf!(ax2, xx, yy, valsp, triangulation = trifaces)
arrows2d!(ax1, vertices[1,:], vertices[2,:], arrx, arry, color=arrcol)
#_cm1 = tricontourf!(ax2, xx, yy, interpolate(ogsuqasg.asg, [0.0,1.0])["Si"][:,end], triangulation = trifaces)
display(f)


#f = Figure(size=(1600,800));
#ax = Axis3(f[1, 1]);
#surface!(ax, asg_expval, 50, ppfun)
#scatter!(ax, asg_expval, z_offset=DistributedSparseGridsPlotting.minval(asg_expval, ppfun), markersize=4)
#ax2 = Axis(f[1, 2]);
#scatter!(ax2, asg_expval)
#display(f)
#
#f = Figure(size=(1600,800));
#ax = Axis3(f[1, 1]);
#surface!(ax, asg_varval, 50, ppfun)
#scatter!(ax, asg_varval, z_offset=minval(asg_varval, ppfun), markersize=4)
#ax2 = Axis(f[1, 2]);
#scatter!(ax2, asg_varval)
#display(f)
