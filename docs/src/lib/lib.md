# Library

## Contents 

```@contents
Pages = ["lib.md"]
Depth = 4
```

## Functions

### Index

```@index
Pages = ["lib.md"]
Depth = 4
```

### Typedefs
```@docs
SampleMethodParams
```

### Structs

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

### General functions

```@docs
init(::OGSUQParams)
scalarwise_comparefct(::VTUFile,::Any,::Any)
```

### Utils

```@docs
dependend_tensor_parameter!(::Ogs6ModelDef, ::String, ::Int, ::Int, ::Any)
dependend_parameter!(::Ogs6ModelDef, ::String, ::String, ::Int, ::Int, ::Any)
```


