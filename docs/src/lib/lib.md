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
`OpenGeoSysUncertaintyQuantification.jl` provides methods for the generation of a stochastic OGS6 project from a validly configured OGS6 project.
```@docs
generatePossibleStochasticParameters
loadStochasticParameters
generateStochasticOGSModell
generateSampleMethodModel
```

## General functions

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


