# OGSUQ

[![][docs-dev-img]][docs-dev-url]

An uncertainty quantification toolbox for [OpenGeoSys 6](https://www.opengeosys.org/).

## Introduction

[OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge.

In simulation-aided planning of safety-related projects, the effects of those uncertainties on the results must be assessed. 
This toolbox is intended to provide all the necessary methods to quantify the uncertainties in a validly configured deterministic OGS6 simulation. 
Special care is taken to ensure reliable and accurate determination of the stochastic moments even when a large amount of data is generated for individual calculations.

The current environment for using this toolbox is individual servers. This means additional local workers are added via the `distributed.addprocs` method. This can be easily extended for the use in cluster environments, but further design decisions must be made first, such as requiring a Network File System (NFS), or the implementation of a mapping of executed snapshots to individual servers.

This toolbox heavily relies upon the following projects:

- [DistributedSparseGrids.jl](https://github.com/baxmittens/DistributedSparseGrids.jl) 
	
	A library implementing an Adaptive Sparse Grid collocation method for integrating memory-heavy objects generated on distributed workers ([JOSS paper](https://joss.theoj.org/papers/10.21105/joss.05003)).

- [DistributedMonteCarlo.jl](https://github.com/baxmittens/DistributedMonteCarlo.jl)

	Analogous to the above (work in progress).

- [Ogs6InputFileHandler.jl](https://github.com/baxmittens/Ogs6InputFileHandler.jl)

	A simple OGS6 input file handler.

- [VTUFileHandler.jl](https://github.com/baxmittens/VTUFileHandler.jl)

	A VTU library for reading and writing vtu files. In addition, all mathematical operators are provided needed for stochastic postprocessing. This results in the datatype `VTUFile` can directly be used with the sparse grid, enabling interpolating complete OGS6 result files ([JOSS paper](https://joss.theoj.org/papers/10.21105/joss.04300)).

- [XDMFFileHandler.jl](https://github.com/baxmittens/XDMFFileHandler.jl)

	Analogous to the above for the XDMF result file format (work in progress).

- [AltInplaceOpsInterface.jl](https://github.com/baxmittens/AltInplaceOpsInterface.jl)

	A simple interface for in-place operators needed in different packages.

Since creating stochastic calculations based on deterministic solutions of discretized partial differential equations is complicated in itself, this project will focus on generating stochastic OGS6 projects.
However, this project could serve as a basis for creating functionalities for generic stochastic calculations. Furthermore, the Julia projects mentioned above can be individually used to help with creating generic stochastic computations.

## Current state of development

**Although in a relatively advanced stage of development, the project should not be used by anyone at this time.**

## Install

## Usage

For more information, see the [documentation](https://baxmittens.github.io/OGSUQ.jl/dev/).

## Implemented features

## Contributions, report bugs and support

Contributions to or questions about this project are welcome. Feel free to create a issue or a pull request on [GitHub](https://github.com/baxmittens/OGSUQ.jl).


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://baxmittens.github.io/OGSUQ.jl/dev/