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
```

## Utils

## Utils adaptive sparse grid 
```@docs
OpenGeoSysUncertaintyQuantification.scalarwise_comparefct(::VTUFile, ::Any, ::Any)
```


## Utils userfile
```@docs
dependend_tensor_parameter!(::Ogs6ModelDef, ::String, ::Int, ::Int, ::Any)
dependend_parameter!(::Ogs6ModelDef, ::String, ::String, ::Int, ::Int, ::Any)
```


