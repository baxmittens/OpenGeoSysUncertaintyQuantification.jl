# Library

## Contents 

```@contents
Pages = ["lib.md"]
Depth = 4
```

## Index

```@index
Pages = ["lib.md"]
Depth = 4
```

## Typedefs
```@docs
SampleMethodParams
```

## Structs

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

## Project setup

`OpenGeoSysUncertaintyQuantification.jl` provides methods for the generation of a stochastic OGS6 model from a validly configured OGS6 project. [`generatePossibleStochasticParameters`](@ref) scans existing OGS6 projects for possible stochastic parameters. [`generateStochasticOGSModell`](@ref) is a helper function which creates an data structure containing all parameters describing the stochastic OGS model, defined by [`StochasticOGSModelParams`](@ref). [`generateSampleMethodModel`](@ref) generates the data structure for the sample method, defined by the abstract type [`SampleMethodParams`](@ref). Currently implented are: [`SparseGridParams`](@ref), [`MonteCarloParams`](@ref), [`MonteCarloSobolParams`](@ref), or [`MonteCarloMorrisParams`](@ref).

```@docs
generatePossibleStochasticParameters
loadStochasticParameters
generateStochasticOGSModell
generateSampleMethodModel
```

## General functions

Given both necessary data structures describing a stochastic OGS6 model have been created, the following methods can be used to initialize the stochastic model and start the sampling procedure. The data structures [`StochasticOGSModelParams`](@ref) and [`SampleMethodParams`](@ref) are automatically written to hard drive as [`XML`](https://github.com/baxmittens/XMLParser.jl/blob/9f28a42e14c238b913d994525d291e89f00a1aad/src/XMLParser/julia2xml.jl#L35) files and can be manipulated in any text editor.

"""julia
ogsuqparams = OGSUQParams("StochasticOGSModelParams.xml", "SampleMethodParams.xml")
ogsuqmc = OGSUQ.init(ogsuqparams)
res = OGSUQ.start!(ogsuqmc)
"""

```@docs
init(::OGSUQParams)
start!
𝔼
variance
```

## Utils
```@docs
CPtoStoch
StochtoCP
```


## Adaptive sparse grid 
```@docs
OpenGeoSysUncertaintyQuantification.scalarwise_comparefct(::VTUFile, ::Any, ::Any)
empirical_cdf
OpenGeoSysUncertaintyQuantification.sample_postproc_fun
```

## Sobols indices 
```@docs
write_sobol_field_result_to_XDMF
write_sobol_multifield_result_to_XDMF
```

## Userfile
```@docs
dependend_tensor_parameter!(::Ogs6ModelDef, ::String, ::Int, ::Int, ::Any)
dependend_parameter!(::Ogs6ModelDef, ::String, ::String, ::Int, ::Int, ::Any)
setStochasticParameter!
setStochasticParameters!
```


