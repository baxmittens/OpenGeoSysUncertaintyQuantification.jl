# OGSUQ
An uncertainty quantification toolbox for [OpenGeoSys 6](https://www.opengeosys.org/).

## Introduction

[OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge.

In simulation-aided planning of safety-related projects, the effects of these uncertainties on the results must be assessed. 
This toolbox is intended to provide all the necessary methods to quantify the uncertainties in a validly configured deterministic OGS6 simulation. 
Special care is taken to ensure reliable and accurate determination of the stochastic moments even when a large amount of data is generated for individual calculations.

The current environment for using this toolbox is individual servers. This means additional local workers are added via the `distributed.addprocs` method. This can be easily extended for the use in cluster environments, but further design decisions must be made first, such as requiring a Network File System (NFS), or the implementation of a mapping of executed snapshots to servers.

This toolbox (will) heavily relies upon the following individual projects:

- [DistributedSparseGrids.jl](https://github.com/baxmittens/DistributedSparseGrids.jl) 
- [DistributedMonteCarlo.jl](https://github.com/baxmittens/DistributedMonteCarlo.jl)
- [Ogs6InputFileHandler.jl](https://github.com/baxmittens/Ogs6InputFileHandler.jl)
- [VTUFileHandler.jl](https://github.com/baxmittens/VTUFileHandler.jl)
- [XDMFFileHandler.jl](https://github.com/baxmittens/XDMFFileHandler.jl)
- [AltInplaceOpsInterface.jl](https://github.com/baxmittens/AltInplaceOpsInterface.jl)

Since creating stochastic calculations based on deterministic solutions of discretized partial differential equations is complicated in itself, this project will focus on generating stochastic OGS6 projects.
However, this project could serve as a basis for creating functionalities for generic stochastic calculations. Furthermore, the Julia projects mentioned above can be individually used to help with creating generic stochastic computations.

## Current state of development

**Although in a relatively advanced stage of development, the project should not be used by anyone at this time.**

## Install

## Implemented features

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
can be used to scan a existing `projectfile` for all existing possible stochastic parameter. What is considered a stochastic parameter is defined by the [`keywords`](https://github.com/baxmittens/OGSUQ.jl/blob/1b1d5d247299df4a69d90c5eec93cefb48e2d74b/src/OGSUQ/utils.jl#L2). This generates an xml-file `file` where all possible stochastic parameters are listed. 

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
- a `outputpath`, where all snapshots will be stored,
- a `stochmethod` (sparse grid or Monte-Carlo, where Monte-Carlo is not yet implemented),
- the number of local workers `n_local_workers`, and, 
- the filename `sogsfile` under which the model is stored as an xml-file. 

This function also creates a file `user_function.jl` which is loaded by all workers and serves as an interface between OGS6 and Julia. Here it is defined how the individual calculations are generated and how the postprocessing results are handled.

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

The following [source code](https://github.com/baxmittens/OGSUQ.jl/blob/main/test/ex2/generate_stoch_params_file.jl) 
```julia
using OGSUQ
projectfile="./project/point_heat_source_2D.prj"
pathes = generatePossibleStochasticParameters(projectfile)
```
return an array of strings with [`OGS6-XML-pathes`](https://github.com/baxmittens/Ogs6InputFileHandler.jl/blob/63944f2bcc54238af568f5f892677925ba171d5a/src/Ogs6InputFileHandler/utils.jl#L51) and generates an XML-file `PossibleStochasticParameters.xml` in the working directory

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
where all parameters possible to select as stochastic parameter are mapped. Since, in this example, an adaptive sparse grid collocation sampling shall be adopted, only two parameters are selected, or, respectively, all other parameters are deleted from the file. The resulting xml-file looks as follows and is stored as `PossibleStochasticParameters.xml` in the working directory.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Array
	 julia:type="String,1"
>
	./media/medium/@id/0/properties/property/?porosity/value
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value
</Array>
```
Here, the porosity and the thermal conductivity of the aqueous liquid are chosen as stochastic parameters.

### Defining the stochastic model

The following [source code](https://github.com/baxmittens/OGSUQ.jl/blob/main/test/ex2/generate_stoch_model.jl) 
```julia
using OGSUQ
projectfile="./project/point_heat_source_2D.prj"
simcall="/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
additionalprojecfilespath="./mesh"
outputpath="./Res"
postprocfiles=["PointHeatSource_ts_10_t_50000.000000.vtu"]
outputpath="./Res"
stochmethod=AdaptiveHierarchicalSparseGrid

stochparampathes = loadStochasticParameters() #load the 2 stochastic parameters defined in "./PossibleStochasticParameters.xml"
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod) # generate the StochasticOGSModelParams

samplemethodparams = generateSampleMethodModel(stochasticmodelparams) # generate the SampleMethodParams
```

generates two XML-files defining the stochastic model.


```xml
<?xml version="1.0" encoding="UTF-8"?>
<StochasticOGSModelParams
	 samplemethod="AdaptiveHierarchicalSparseGrid"
	 num_local_workers="50"
	 userfunctionfile="./user_functions.jl"
	 file="StochasticOGSModelParams.xml"
>
	<OGS6ProjectParams
		 julia:fieldname="ogsparams"
		 projectfile="./project/point_heat_source_2D.prj"
		 simcall="/home/ogs_auto_jenkins/temporary_versions/native/master/ogs6_2023-02-23/bin/ogs"
		 additionalprojecfilespath="./mesh"
		 outputpath="./Res"
	>
		<Array
			 julia:type="String,1"
			 julia:fieldname="postprocfiles"
		>
			PointHeatSource_ts_10_t_50000.000000.vtu
		</Array>
	</OGS6ProjectParams>
	<Array
		 julia:type="StochasticOGS6Parameter,1"
		 julia:fieldname="stochparams"
	>
		<StochasticOGS6Parameter
			 path="./media/medium/@id/0/properties/property/?porosity/value"
			 valspec="1"
			 lower_bound="0.15"
			 upper_bound="0.60"
		>
			<Uniform
				 julia:type="Float64"
				 julia:fieldname="dist"
				 a="0.15"
				 b="0.60"
			/>
		</StochasticOGS6Parameter>
		<StochasticOGS6Parameter
			 path="./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value"
			 valspec="1"
			 lower_bound="0.5"
			 upper_bound="0.7"
		>
			<Uniform
				 julia:type="Float64"
				 julia:fieldname="dist"
				 a="0.5"
				 b="0.7"
			/>
		</StochasticOGS6Parameter>
	</Array>
</StochasticOGSModelParams>
```


```xml
<?xml version="1.0" encoding="UTF-8"?>
<SparseGridParams
	 N="2"
	 CT="Float64"
	 RT="VTUFile"
	 init_lvl="3"
	 maxlvl="20"
	 tol="10000.0"
	 file="SampleMethodParams.xml"
>
	<Array
		 julia:type="Int64,1"
		 julia:fieldname="pointprobs"
	>
		1
		1
	</Array>
</SparseGridParams>

```

| | |
|:-------------------------:|:-------------------------:|
|<img src="https://user-images.githubusercontent.com/100423479/223154558-4b94d7a2-e93b-45ef-9783-11437ae23b35.png" width="350" height="300" /> |  <img src="https://user-images.githubusercontent.com/100423479/223125844-276bcb9b-8ce5-4072-9e20-11f6a3e67d7b.png" width="300" height="300" />|
| resulting sparse grid  | response surface |


![image](https://user-images.githubusercontent.com/100423479/223154558-4b94d7a2-e93b-45ef-9783-11437ae23b35.png)
