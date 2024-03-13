# Library

## Contents 

```@contents
Pages = ["lib.md"]
Depth = 4
```

## Project setup

`OpenGeoSysUncertaintyQuantification.jl` provides methods for the generation of a stochastic OGS6 model from a validly configured OGS6 project. [`generatePossibleStochasticParameters`](@ref) scans existing OGS6 projects for possible stochastic parameters. [`generateStochasticOGSModell`](@ref) is a helper function which creates an data structure containing all parameters describing the stochastic OGS model, defined by [`StochasticOGSModelParams`](@ref). [`generateSampleMethodModel`](@ref) generates the data structure for the sample method, defined by the abstract type [`SampleMethodParams`](@ref). Currently implented are: [`SparseGridParams`](@ref), [`MonteCarloParams`](@ref), [`MonteCarloSobolParams`](@ref), or [`MonteCarloMorrisParams`](@ref).

```@docs
generatePossibleStochasticParameters
loadStochasticParameters
generateStochasticOGSModell
generateSampleMethodModel
```

## Structs

This are the main data structure needed for handling a stochastic OGS6 model. [`OGS6ProjectParams`](@ref), [`StochasticOGS6Parameter`](@ref), [`StochasticOGSModelParams`](@ref), [`SparseGridParams`](@ref), [`MonteCarloParams`](@ref), [`MonteCarloSobolParams`](@ref), and [`MonteCarloMorrisParams`](@ref) describing the stochastic model and containing all needed data to handle the OGS6 simulation calls. This stuctures can be loaded from and written to hard drive and manipulated with an text editor.
[`OGSUQASG`](@ref), [`OGSUQMC`](@ref), [`OGSUQMCSobol`](@ref), [`OGSUQMCMorris`](@ref) are the initialized stochastic models containing the data structures and run-time objects.

```@docs
OGS6ProjectParams
StochasticOGS6Parameter
StochasticOGSModelParams
SparseGridParams
MonteCarloParams
MonteCarloSobolParams
MonteCarloMorrisParams
OGSUQParams
OGSUQASG
OGSUQMC
OGSUQMCSobol
OGSUQMCMorris
```

## General functions

Given both necessary data structures describing a stochastic OGS6 model have been created, the following methods can be used to initialize the stochastic model and start the sampling procedure:

```julia
ogsuqparams = OGSUQParams("StochasticOGSModelParams.xml", "SampleMethodParams.xml")
ogsuqmc = OGSUQ.init(ogsuqparams)
res = OGSUQ.start!(ogsuqmc)
```

The data structures [`StochasticOGSModelParams`](@ref) and [`SampleMethodParams`](@ref) are automatically written to hard drive as [`XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35) files and can be manipulated in any text editor.
The [`init`](@ref) function initalizes the model and adds the local workers. [`start!`](@ref) starts the sampling procedure for the [adaptive sparse grid](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/). For [Monte Carlo](@ref) methods only the sample points are generated upon calling [`start!`]. The sampling procedure, i.e. the determinitic OGS6 calls, are only executed if [`𝔼`](@ref) or [`variance`](@ref) is called, since for Monte Carlo methods, the results are only loaded partially into memory.   

```@docs
init(::OGSUQParams)
start!
𝔼
variance
```

## Utils

General helper function for handling a stochastic OGS6 project.

```@docs
CPtoStoch
StochtoCP
```


## Adaptive sparse grid

If an [`OGSUQASG`](@ref) model is used the [`adaptive sparse grid`](https://baxmittens.github.io/DistributedSparseGrids.jl/dev/)) serves as a surrogate model. The idea is to sample the physical state space and to integrate this state space against the multivariate pdf in an additional step. This is done because the integration of the multivariate pdf is often times much harder to integrate than the physical model, for example in the case of a multivariate normal distribution. The empirical output distributions can be integrated by [`empirical_cdf`](@ref).

```@docs
OpenGeoSysUncertaintyQuantification.scalarwise_comparefct(::VTUFile, ::Any, ::Any)
empirical_cdf
OpenGeoSysUncertaintyQuantification.sample_postproc_fun
```

## Sobols indices

With `OpenGeoSysUncertaintyQuantification.jl`, Sobol indices of whole OGS6 postprocessing results can be integrated. To write such results to hard drive, the function [`write_sobol_field_result_to_XDMF`](@ref) and [`write_sobol_multifield_result_to_XDMF`](@ref) are used.

```@docs
write_sobol_field_result_to_XDMF
write_sobol_multifield_result_to_XDMF
```

## Userfile

Upon the generation of the stochastic model, a user file (userfile.jl) is generated as well. This userfile executes the OGS6 simulation call. The stochastic model as well as the quantities of interest can be altered in this file. In case of a altered quantity of interest, the return type in [`SampleMethodParams`] has to be altered, accordingly.

```@docs
dependend_tensor_parameter!(::Ogs6ModelDef, ::String, ::Int, ::Int, ::Any)
dependend_parameter!(::Ogs6ModelDef, ::String, ::String, ::Int, ::Int, ::Any)
setStochasticParameter!
setStochasticParameters!
```

## Typedefs

Here are some supertypes used for dispatching.

```@docs
SampleMethodParams
OpenGeoSysUncertaintyQuantification.AbstractOGSUQ
OpenGeoSysUncertaintyQuantification.AbstractOGSUQMonteCarlo
OpenGeoSysUncertaintyQuantification.AbstractOGSUQSensitivity
```

## Index

```@index
Pages = ["lib.md"]
Depth = 4
```
