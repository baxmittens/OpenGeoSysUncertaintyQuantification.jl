# OGSUQ
An uncertainty quantification toolbox for [OpenGeoSys 6](https://www.opengeosys.org/)

## Introduction

[OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge.

In simulation-aided planning of safety-related projects, the effects of these uncertainties on the results must be assessed. 
This toolbox is intended to provide all the necessary methods to quantify the uncertainties in a validly configured deterministic OGS6 simulation. 
Special care is taken to ensure reliable and accurate determination of the stochastic moments even when large amounts of data are generated even for individual calculations.

The current environment for using this toolbox is individual servers. This means additional workers are added via the `distributed.addprocs` method. This can be easily extended for use in cluster environments, but further design decisions must be made first, such as requiring a Network File System (NFS), or a mapping of servers and executed snapshots.

This toolbox (will) consists of the following individual projects:

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
