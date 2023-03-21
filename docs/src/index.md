# OGSUQ.jl

## The general idea for the creation of a stochastic OGS6 project

The general idea is to always start with a fully configured and running deterministic OGS6 project. There are three basic functions which create three individual xml-files. These files are human-readable and can be manually configured and duplicated for the use in other projects.

The first function 
```julia
generatePossibleStochasticParameters(
	projectfile::String, 
	file::String="./PossibleStochasticParameters.xml", 
	keywords::Vector{String}=ogs_numeric_keyvals
	)
```
can be used to scan a existing `projectfile` for all existing possible stochastic parameter. What is considered a stochastic parameter is defined by the [`keywords`](./src/OGSUQ/utils.jl#L2). This generates an xml-file `file` where all possible stochastic parameters are listed. 

The second funtion

```julia
generateStochasticOGSModell(
	projectfile::String,
	simcall::String,
	additionalprojecfilespath::String,
	postprocfile::Vector{String},
	stochpathes::Vector{String},
	outputpath="./Res",
	stochmethod=AdaptiveHierarchicalSparseGrid,
	n_local_workers=50,
	keywords=ogs_numeric_keyvals,
	sogsfile="StochasticOGSModelParams.xml"
	)
```
creates an xml-file which defines the so-called `StochasticOGSModelParams`. It is defined by 
- the location to the existing `projectfile`, 
- the `simcall` (e.g. `"path/to/ogs/bin/ogs"`), 
- a `additionalprojecfilespath` where meshes and other files can be located which are copied in each individual folder for a OGS6-snapshot, 
- the path to one or more `postprocfile`s, 
- the stochpathes, generated with `generatePossibleStochasticParameters`, manipulated by the user, and loaded by the `loadStochasticParameters`-function,
- an `outputpath`, where all snapshots will be stored,
- a `stochmethod` (sparse grid or Monte-Carlo, where Monte-Carlo is not yet implemented),
- the number of local workers `n_local_workers`, and, 
- the filename `sogsfile` under which the model is stored as an xml-file. 

This function also creates a file `user_function.jl` which is loaded by all workers and serves as an interface between OGS6 and Julia. Here it is defined how the individual snaptshots are generated and how the postprocessing results are handled.

The third and last function

```julia
generateSampleMethodModel(
	sogsfile::String, 
	anafile="SampleMethodParams.xml"
	)
# or
generateSampleMethodModel(
	sogs::StochasticOGSModelParams, 
	anafile="SampleMethodParams.xml"
	)
```
creates an xml-file `anafile` with all necessary parameters for the chosen sample method in the `StochasticOGSModelParams`.

## Usage

In this chapter, [Ex2](https://github.com/baxmittens/OGSUQ.jl/tree/main/test/ex2) is taken a an example. The underlying deterministic OGS6 project is the [point heat source example](https://www.opengeosys.org/docs/benchmarks/th2m/saturatedpointheatsource/) ([Thermo-Richards-Mechanics project files](https://gitlab.opengeosys.org/ogs/ogs/-/tree/master/Tests/Data/ThermoRichardsMechanics/PointHeatSource)).


### Defining the stochastic dimensions

The following [lines of code](./test/ex2/generate_stoch_params_file.jl) 
```julia
using OGSUQ
projectfile="./project/point_heat_source_2D.prj"
pathes = generatePossibleStochasticParameters(projectfile)
```
return an array of strings with [`OGS6-XML-pathes`](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/63944f2bcc54238af568f5f892677925ba171d5a/src/Ogs6InputFileHandler/utils.jl#L51) and generates an XML-file [`PossibleStochasticParameters.xml`](./test/ex2/PossibleStochasticParameters.xml) in the working directory

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Array
	 julia:type="String,1"
>
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?specific_heat_capacity/value
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value
			.
			.
			.
	./parameters/parameter/?displacement0/values
	./parameters/parameter/?pressure_ic/values
</Array>
```
where all parameters possible to select as stochastic parameter are mapped. Since, in this example, an adaptive sparse grid collocation sampling shall be adopted, only two parameters, the porosity and the thermal conductivity of the aqueous liquid,
```
./media/medium/@id/0/properties/property/?porosity/value
./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value
```
are selected. Thus, all other parameters are deleted from the file. The resulting xml-file is stored as [`altered_PossibleStochasticParameters.xml`](./test/ex2/altered_PossibleStochasticParameters.xml) in the working directory.

### Defining the stochastic model

The following [code snippet](./test/ex2/generate_stoch_model.jl) 
```julia
using OGSUQ
projectfile="./project/point_heat_source_2D.prj"
simcall="/path/to/ogs/bin/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["PointHeatSource_ts_10_t_50000.000000.vtu"]
outputpath="./Res"
stochmethod=AdaptiveHierarchicalSparseGrid
n_local_workers=50

stochparampathes = loadStochasticParameters("altered_PossibleStochasticParameters.xml")
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod,
	n_local_workers) # generate the StochasticOGSModelParams

samplemethodparams = generateSampleMethodModel(stochasticmodelparams) # generate the SampleMethodParams
```

generates two XML-files, [`StochasticOGSModelParams.xml`](./test/ex2/StochasticOGSModelParams.xml) and [`SampleMethodParams.xml`](./test/ex2/SampleMethodParams.xml), defining the stochastic model.

Again, these files are altered and stored under [`altered_StochasticOGSModelParams.xml`](./test/ex2/altered_StochasticOGSModelParams.xml) and [`altered_SampleMethodParams.xml`](./test/ex2/altered_SampleMethodParams.xml).

In the former, the two stochastic parameters are altered. The probability distribution of the porosity is changed from `Uniform` to `Normal` with mean `μ=0.375` and standard deviation `σ=0.1`.
```xml
<StochasticOGS6Parameter
	 path="./media/medium/@id/0/properties/property/?porosity/value"
	 valspec="1"
	 lower_bound="0.15"
	 upper_bound="0.60"
>
	<Normal
		 julia:type="Float64"
		 julia:fieldname="dist"
		 μ="0.375"
		 σ="0.1"
	/>
</StochasticOGS6Parameter>
```
Note that for efficiency, the normal distribution is changed to a [truncated normal distribution](https://en.wikipedia.org/wiki/Truncated_normal_distribution) by the parameters `lower_bound=0.15` and `upper_bound=0.60`. This results in an integration error of approximately 2.5% for this example. See the picture below for a visualization of the normal distribution $\mathcal{N}$ and the truncated normal distribution $\bar{\mathcal{N}}$.

<p align="center">
	<img src="https://user-images.githubusercontent.com/100423479/223678210-58ebf8c4-731a-4a5e-9037-693f80d431b4.png" width="350" height="350" />
</p>

The second parameter, the thermal conductivity, is set up as a truncated normal distribution with mean `μ=0.6`, standard deviation `σ=0.05`, `lower_bound=0.5`, and, `upper_bound=0.7`. The multivariate truncated normal distribution resulting from the convolution of both one-dimensional distributions is pictured below. Note, that the distribution has been transformed to the domain $[-1,1]^2$ of the [sparse grid](https://github.com/baxmittens/DistributedSparseGrids.jl).

<p align="center">
	<img src="https://user-images.githubusercontent.com/100423479/223682880-2be481cc-986a-4f00-a47a-042d0b0684e5.png" width="400" height="250" />
</p>

The second file [`altered_SampleMethodParams.xml`](./test/ex2/altered_SampleMethodParams.xml) defines the sample method parameters such as
- the number of dimensions `N=2`,
- the return type `RT="VTUFile"` (see [VTUFileHandler.jl](https://github.com/baxmittens/VTUFileHandler.jl))
- the number of initial hierachical level of the sparse grid `init_lvl=4`,
- the number of maximal hierarchical level of the sparse grid `maxlvl=20`, and,
- the minimum hierarchical surplus for the adaptive refinement `tol=100000.0`.

Note, that the refinement tolerance was chosen as a large value since at the moment the reference value is the `LinearAlgebra.norm(::VTUFile)` of the entire result file.

### Sampling the model

The following [lines of code](./test/ex2/start.jl)

```julia
using OGSUQ
ogsuqparams = OGSUQParams("altered_StochasticOGSModelParams.xml", "altered_SampleMethodParams.xml")
ogsuqasg = OGSUQ.init(ogsuqparams)
OGSUQ.start!(ogsuqasg)
expval,asg_expval = OGSUQ.𝔼(ogsuqasg)
```

loads the parameters `ogsuqparams`, initializes the model `ogsuqasg`, and, starts the sampling procedure. Finally the expected value is integrated.

- Initializing the model `OGSUQ.init(ogsuqparams)` consists of two steps
	
	1. Adding all local workers (in this case 50 local workers)
	2. Initializing the adaptive sparse grid.

- Starting the sampling procedure `OGSUQ.start!(ogsuqasg)` first creates 4 initial hierarchical levels levels and, subsequently, starts the adaptive refinement.
	
	This first stage results in an so-called *surrogate model* of the physical domain defined by the boundaries of the stochastic parameters

	| | |
	|:-------------------------:|:-------------------------:|
	|<img src="https://user-images.githubusercontent.com/100423479/223154558-4b94d7a2-e93b-45ef-9783-11437ae23b35.png" width="350" height="300" /> |  <img src="https://user-images.githubusercontent.com/100423479/223125844-276bcb9b-8ce5-4072-9e20-11f6a3e67d7b.png" width="300" height="300" />|
	| resulting sparse grid  | response surface |


- Computation of the expected value


# DistributedSparseGrids.jl

A Julia library that implements an Adaptive Sparse Grid collocation method for integrating memory-heavy objects generated on distributed workers ([link to GitHub repository](https://github.com/baxmittens/DistributedSparseGrids.jl)).

For an alternative implementation, see [AdaptiveSparseGrids.jl](https://github.com/jacobadenbaum/AdaptiveSparseGrids.jl).

## Contents

```@contents
Pages = ["index.md", "lib/lib.md"]
Depth = 3
```

## Introduction

To mitigate the "curse of dimensionality" that occurs in the integration or interpolation of high-dimensional functions using tensor-product discretizations, sparse grids use Smolyak's quadrature rule. This is particularly useful if the evaluation of the underlying function is costly. In this library, an Adaptive Sparse Grid Collocation method with a local hierarchical Lagrangian basis, first proposed by [Ma and Zabaras (2010)](https://www.sciencedirect.com/science/article/pii/S002199910900028X), is implemented. For more information about the construction of Sparse Grids, see e.g. [Gates and Bittens (2015)](https://arxiv.org/abs/1509.01462).

## Install

```julia
import Pkg
Pkg.install("DistributedSparseGrids")
```

## Implemented features

-	Nested one-dimensional Clenshaw-Curtis rule

-	Smolyak's sparse grid construction

-	local hierarchical Lagrangian basis

-	different pointsets (open, closed, halfopen)

-	adaptive refinement

-	distributed function evaluation with ```Distributed.remotecall_fetch```

-	multi-threaded calculation of basis coefficients with ```Threads.@threads```

-	usage of arbitrary return types 

-	integration

-	experimental: integration over $X_{\sim (i)}$ (the $X_{\sim (i)}$  notation indicates the set of all variables except $X_{i}$).

## Usage

### Point sets

When using sparse grids, one can choose whether the $2d$ second-level collocation points should lay on the boundary of the domain or in the middle between the origin and the boundary. (There are other choices as well.) This results in two different sparse grids, the former with almost all points on the boundary and on the coordinate axes, the latter with all points in the interior of the domain. Since one can choose for both one-dimensional children of the root point individually, there exist a multitude of different point sets for Sparse Grids.

```julia
DistributedSparseGrids
using StaticArrays 

function sparse_grid(N::Int,pointpros,nlevel=6,RT=Float64,CT=Float64)
	# define collocation point
	CPType = CollocationPoint{N,CT}
	# define hierarchical collocation point
	HCPType = HierarchicalCollocationPoint{N,CPType,RT}
	# init grid
	asg = init(AHSG{N,HCPType},pointpros)
	#set of all collocation points
	cpts = Set{HierarchicalCollocationPoint{N,CPType,RT}}(collect(asg))
	# fully refine grid nlevel-1 times
	for i = 1:nlevel-1
		union!(cpts,generate_next_level!(asg))
	end
	return asg
end

# define point properties 
#	1->closed point set
# 	2->open point set
#	3->left-open point set
#	4->right-open point set

asg01 = sparse_grid(1, @SVector [1]) 
asg02 = sparse_grid(1, @SVector [2]) 
asg03 = sparse_grid(1, @SVector [3]) 

asg04 = sparse_grid(2, @SVector [1,1]) 
asg05 = sparse_grid(2, @SVector [2,2]) 
asg06 = sparse_grid(2, @SVector [1,2]) 
asg07 = sparse_grid(2, @SVector [2,1]) 
asg08 = sparse_grid(2, @SVector [3,3]) 
asg09 = sparse_grid(2, @SVector [4,4]) 
asg10 = sparse_grid(2, @SVector [3,1]) 
asg11 = sparse_grid(2, @SVector [2,3]) 
asg12 = sparse_grid(2, @SVector [4,2]) 
```

![](./assets/ps1d.png)
![](./assets/ps2d.png)

### Integration and Interpolation

```julia
asg = sparse_grid(4, @SVector [1,1,1,1]) 

#define function: input are the coordinates x::SVector{N,CT} and an unique id ID::String (e.g. "1_1_1_1")
fun1(x::SVector{N,CT},ID::String) = sum(x.^2)

# initialize weights
@time init_weights!(asg, fun1)

# integration
integrate(asg)

# interpolation
x = rand(4)*2.0 .- 1.0
val = interpolate(asg,x)	
```

### Distributed function evaluation

```julia
asg = sparse_grid(4, @SVector [1,1,1,1]) 

# add worker and register function to all workers
using Distributed
addprocs(2)
ar_worker = workers()
@everywhere begin
    using StaticArrays
    fun2(x::SVector{4,Float64},ID::String) = 1.0
end

# Evaluate the function on 2 workers
distributed_init_weights!(asg, fun2, ar_worker)
```

### Using custom return types

For custom return type ```T``` to work, following functions have to be implemented

```julia
import Base: +,-,*,/,^,zero,zeros,one,ones,copy,deepcopy

+(a::T, b::T) 
+(a::T, b::Float64) 
*(a::T, b::Float64) 
-(a::T, b::Matrix{Float64})
-(a::T, b::Float64) 
zero(a::T) 
zeros(a::T) 
one(a::T) 
one(a::T) 
copy(a::T)
deepcopy(a::T)
```

This is already the case for many data types. Below  ```RT=Matrix{Float64}``` is used.

```julia
# sparse grid with 5 dimensions and levels
pointpros = @SVector [1,2,3,4,1]
asg = sparse_grid(5, pointpros, 6, Matrix{Float64}) 

# define function: input are the coordinates x::SVector{N,CT} and an unique id ID::String (e.g. "1_1_1_1_1_1_1_1_1_1"
# for the root poin in five dimensions)
fun3(x::SVector{N,CT},ID::String) = ones(100,100).*x[1]

# initialize weights
@time init_weights!(asg, fun3)
```
### In-place operations

There are many mathematical operations executed which allocate memory while evaluating the hierarchical interpolator. Many of these allocations can be avoided by additionally implementing the ```in-place operations``` interface for data type ```T```. At the moment, this feature is provided through the interface package [AltInplaceOpsInterface.jl](https://github.com/baxmittens/AltInplaceOpsInterface.jl) and `LinearAlgebra.mul!` (the code was initially written for Julia 0.6). In future releases, this interface could be rendered obsolete due to implementing [standard julia interface function and proper broadcasting](https://docs.julialang.org/en/v1/manual/interfaces/), but some research is probably still needed to implement this properly.

```julia
import LinearAlgebra
import LinearAlgebra: mul!
import AltInplaceOpsInterface

AltInplaceOpsInterface.add!(a::T, b::T) 
AltInplaceOpsInterface.add!(a::T, b::Float64)
AltInplaceOpsInterface.minus!(a::T, b::T) 
AltInplaceOpsInterface.minus!(a::T, b::Float64)  
AltInplaceOpsInterface.pow!(a::T, b::Float64)  
LinearAlgebra.mul!(a::T, b::Float64) 
LinearAlgebra.mul!(a:T, b::T, c::Float64)
```

For Matrix{Float64} this interface is already implemented.

```julia
# initialize weights
@time init_weights_inplace_ops!(asg, fun3)
```

### Distributed function evaluation and in-place operations

```julia
# initialize weights
@time distributed_init_weights_inplace_ops!(asg, fun3, ar_worker)
```


### Adaptive Refinement

```julia
# Sparse Grid with 4 initial levels
pp = @SVector [1,1]
asg = sparse_grid(2, pp, 4)

# Function with curved singularity
fun1(x::SVector{2,Float64},ID::String) =  (1.0-exp(-1.0*(abs(2.0 - (x[1]-1.0)^2.0 - (x[2]-1.0)^2.0) +0.01)))/(abs(2-(x[1]-1.0)^2.0-(x[2]-1.0)^2.0)+0.01)

init_weights!(asg, fun1)

# adaptive refine
for i = 1:20
# call generate_next_level! with tol=1e-5 and maxlevels=20
cpts = generate_next_level!(asg, 1e-5, 20)
init_weights!(asg, collect(cpts), fun1)
end

# plot
import PlotlyJS
surfplot = PlotlyJS.surface(asg, 100)
gridplot = PlotlyJS.scatter3d(asg)
PlotlyJS.plot([surfplot, gridplot])
```

![](./assets/func.png)

### Plotting

#### 1d

```julia
# grid plots
PlotlyJS.scatter(sg::AbstractHierarchicalSparseGrid{1,HCP}, lvl_offset::Bool=false; kwargs...) 
UnicodePlots.scatterplot(sg::AbstractHierarchicalSparseGrid{1,HCP}, lvl_offset::Bool=false)

# response function plots
UnicodePlots.lineplot(asg::AbstractHierarchicalSparseGrid{1,HCP}, npts = 1000, stoplevel::Int=numlevels(asg))
PlotlyJS.surface(asg::SG, npts = 1000, stoplevel::Int=numlevels(asg); kwargs...)
```

#### 2d

```julia
# grid plots
PlotlyJS.scatter(sg::AbstractHierarchicalSparseGrid{2,HCP}, lvl_offset::Float64=0.0, color_order::Bool=false) 
UnicodePlots.scatterplot(sg::AbstractHierarchicalSparseGrid{2,HCP})
PlotlyJS.scatter3d(sg::AbstractHierarchicalSparseGrid{2,HCP}, color_order::Bool=false, maxp::Int=1)

# response function plot
PlotlyJS.surface(asg::AbstractHierarchicalSparseGrid{2,HCP}, npts = 20; kwargs...)
```

#### 3d

```julia
# grid plot
PlotlyJS.scatter3d(sg::AbstractHierarchicalSparseGrid{3,HCP}, color_order::Bool=false, maxp::Int=1)
```

## Contributions, report bugs and support

Contributions to or questions about this project are welcome. Feel free to create a issue or a pull request on [GitHub](https://github.com/baxmittens/VTUFileHandler.jl).