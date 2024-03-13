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

## General functions

```@docs
init(::OGSUQParams)

start!
𝔼
variance
```

## Project setup
```@docs
generatePossibleStochasticParameters
loadStochasticParameters
generateStochasticOGSModell
generateSampleMethodModel
```

## Utils
```@docs
CPtoStoch
StochtoCP
```


## Utils adaptive sparse grid 
```@docs
OpenGeoSysUncertaintyQuantification.scalarwise_comparefct(::VTUFile, ::Any, ::Any)
empirical_cdf
sample_postproc_fun
```


## Utils userfile
```@docs
dependend_tensor_parameter!(::Ogs6ModelDef, ::String, ::Int, ::Int, ::Any)
dependend_parameter!(::Ogs6ModelDef, ::String, ::String, ::Int, ::Int, ::Any)
setStochasticParameter!
setStochasticParameters!
```


