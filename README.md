# OGSUQ
An uncertainty quantification toolbox for [OpenGeoSys 6](https://www.opengeosys.org/)

## Introduction

[OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge.

In simulation-aided planning of safety-related projects, the effects of these uncertainties on the results must be assessed. 
This toolbox is intended to provide all the necessary methods to quantify the uncertainties in a validly configured deterministic OGS6 simulation. 
Special care is taken to ensure reliable and accurate determination of the stochastic moments even when large amounts of data are generated even for individual calculations.

The current environment for using this toolbox is individual servers. This means additional workers are added via the `distributed.addprocs` method. This can be easily extended for use in cluster environments, but further design decisions must be made first, such as requiring a Network File System (NFS), or a mapping of servers and executed snapshots.

This toolbox (will) heavily relies upon the following individual projects:

- [DistributedSparseGrids.jl](https://github.com/baxmittens/DistributedSparseGrids.jl) 
- [DistributedMonteCarlo.jl](https://github.com/baxmittens/DistributedMonteCarlo.jl)
- [Ogs6InputFileHandler.jl](https://github.com/baxmittens/Ogs6InputFileHandler.jl)
- [VTUFileHandler.jl](https://github.com/baxmittens/VTUFileHandler.jl)
- [XDMFFileHandler.jl](https://github.com/baxmittens/XDMFFileHandler.jl)
- [AltInplaceOpsInterface.jl](https://github.com/baxmittens/AltInplaceOpsInterface.jl)

## Current state of development

**Although in a relatively advanced stage of development, the project should not be used by anyone at this time.**

## Install

## Implemented features

## Usage

[Ex2](https://github.com/baxmittens/OGSUQ.jl/tree/main/test/ex2) is taken a an example. The underlying deterministic OGS6 project is the [point heat source example](https://www.opengeosys.org/docs/benchmarks/th2m/saturatedpointheatsource/) ([Thermo-Richards-Mechanics project files](https://gitlab.opengeosys.org/ogs/ogs/-/tree/master/Tests/Data/ThermoRichardsMechanics/PointHeatSource)).


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
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?density/value
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_expansivity/value
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?viscosity/value
	./media/medium/@id/0/phases/phase/?Solid/properties/property/?density/value
	./media/medium/@id/0/phases/phase/?Solid/properties/property/?thermal_conductivity/value
	./media/medium/@id/0/phases/phase/?Solid/properties/property/?specific_heat_capacity/value
	./media/medium/@id/0/phases/phase/?Solid/properties/property/?thermal_expansivity/value
	./media/medium/@id/0/properties/property/?saturation/value
	./media/medium/@id/0/properties/property/?relative_permeability/value
	./media/medium/@id/0/properties/property/?permeability/value
	./media/medium/@id/0/properties/property/?porosity/value
	./media/medium/@id/0/properties/property/?biot_coefficient/value
	./parameters/parameter/?E/value
	./parameters/parameter/?nu/value
	./parameters/parameter/?T0/value
	./parameters/parameter/?dirichlet0/value
	./parameters/parameter/?Neumann0/value
	./parameters/parameter/?temperature_ic/value
	./parameters/parameter/?pressure_bc_left/value
	./parameters/parameter/?temperature_bc_left/value
	./parameters/parameter/?temperature_source_term/value
	./processes/process/specific_body_force
	./parameters/parameter/?displacement0/values
	./parameters/parameter/?pressure_ic/values
</Array>
```
where all parameters possible to select as stochastic parameter are mapped. Since, in this example, an adaptive sparse grid collocation sampling shall be adopted, only two parameters are selected, or, respectively, all other parameters are deleted from the file.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Array
	 julia:type="String,1"
>
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?specific_heat_capacity/value
	./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value
</Array>
```

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

stochparampathes = loadStochasticParameters()
	
stochasticmodelparams = generateStochasticOGSModell(
	projectfile,
	simcall,
	additionalprojecfilespath,
	postprocfiles,
	stochparampathes,
	outputpath,
	stochmethod)

samplemethodparams = generateSampleMethodModel(stochasticmodelparams)
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
			 path="./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?specific_heat_capacity/value"
			 valspec="1"
			 lower_bound="3852.0"
			 upper_bound="4708.0"
		>
			<Uniform
				 julia:type="Float64"
				 julia:fieldname="dist"
				 a="3852.0"
				 b="4708.0"
			/>
		</StochasticOGS6Parameter>
		<StochasticOGS6Parameter
			 path="./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value"
			 valspec="1"
			 lower_bound="0.54"
			 upper_bound="0.6599999999999999"
		>
			<Uniform
				 julia:type="Float64"
				 julia:fieldname="dist"
				 a="0.54"
				 b="0.6599999999999999"
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
	 tol="0.01"
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

<img src="https://user-images.githubusercontent.com/100423479/223125219-45af259f-72fc-40d3-b08e-3c9f029aff15.png" width="350" height="300" />
<img src="https://user-images.githubusercontent.com/100423479/223125844-276bcb9b-8ce5-4072-9e20-11f6a3e67d7b.png" width="300" height="300" />
