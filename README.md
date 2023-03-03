# OGSUQ
An uncertainty quantification toolbox for [OpenGeoSys 6](https://www.opengeosys.org/)

## Introduction

[OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge.

In simulation-aided planning of safety-related projects, the effects of these uncertainties on the results must be assessed. 
This toolbox is intended to provide all the necessary methods to quantify the uncertainties for a deterministic OGS6 simulation. 
Special care is taken to ensure reliable and accurate determination of the stochastic moments even when large amounts of data are generated even for individual calculations.

The current environment for using this toolbox is individual servers. This means additional workers are added via the `distributed.addprocs` method. This can be easily extended for use in cluster environments, but further design decisions must be made first, such as requiring a Network File System (NFS).

## Install

## Implemented features

## Usage
