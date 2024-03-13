---
title: 'OpenGeoSysUncertaintyQuantification.jl: a Julia library implementing an uncertainty quantification toolbox for OpenGeoSys'
tags:
  - Julia
  - stochastics
  - high-performance computing
  - OpenGeoSys
authors:
  - name: Maximilian Bittens
    orcid: 0000-0001-9954-294X
#   equal-contrib: true
    affiliation: 1 # (Multiple affiliations must be quoted)
affiliations:
 - name: Federal Institute for Geosciences and Natural Resources (BGR), Germany
   index: 1
date: 17 September 2023
bibliography: paper.bib

# Optional fields if submitting to a AAS journal too, see this blog post:
# https://blog.joss.theoj.org/2018/12/a-new-collaboration-with-aas-publishing
#aas-doi: 10.3847/xxxxx <- update this with the DOI from AAS once you know it.
#aas-journal: Astrophysical Journal <- The name of the AAS journal.
---

# Abstract

In simulation-aided design of saftey-related projects, the effects of uncertainties in the input parameters on the outcome are often of great interest. [OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge. [OpenGeoSysUncertaintyQuantification.jl](https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl) is a Julia library which provides all the necessary methods for global sensitivity analysis and uncertaintiy quantification in a validly configured deterministic OGS6 model.

# Statement of need

Stability verifications for large structures can often only be carried out with the help of numerical simulations. A particularly difficult example is the safe storage of highly radioactive waste in subsurface repositories. These are usually planned at depths of several hundred meters. The heat radiated by the fuel rods can influence thermal-hydraulic-mechanical processes down to depths of several kilometers. Numerical simulations are needed to ensure site safety. Because of the outstanding interest in the safety of these repositories, the uncertainties are also given special attention. OpenGeoSys is a frequently used simulation tool in the German research community dedicated to the containment-safe storage of radioactive waste. Due to legal requirements in the repository safety ordinance, it is necessary to quantify input uncertainties of a deterministic OGS6 model.

Parameterizing a THM model in OpenGeoSys [@kolditz2012opengeosys] is complex and time-consuming due to the large number of possible input parameters. For easier applicability, the decision was made not to design this package as a generic uncertainty quantification framework, but to relate it explicitly to OGS6. Nevertheless, care was taken to ensure that the underlying packages are as generic as possible and can be used in other projects.

For this toolbox, following stochastic modeling strategy was chosen: the less is known about the effect of the input uncertainty onto the output, the more general the quantity of interest should be selected, such that as a first step the selection of a complete OGS6 postprocessing result is a viable option. Thereby, this approach provides methods to `explore` uncertainties in the OGS6 simulation output.

The OpenGeoSys community commonly uses Python, however for this project Julia was chosen due to its superior efficiency and built-in capabilities for distributive computing.

To this date, there is no uncertainty quantification toolbox for OpenGeoSys, neither in Python nor in the Julia language. However, there is a general purpose uncertainty quantificationns available for the Julia language named [UncertaintyQuantification.jl](https://github.com/FriesischScott/UncertaintyQuantification.jl).

# Features

Most of all functionalities of this package are outsourced into independent julia packages to maintain their generic character. Therefore, OpenGeoSysUncertaintyQuantification.jl serves as an umbrella project for the following projects:

- [DistributedSparseGrids.jl](https://github.com/baxmittens/DistributedSparseGrids.jl) [@bittens2023distributedsparsegrids]
  
  A library implementing an Adaptive Sparse Grid collocation method for integrating memory-heavy objects generated on distributed workers.

- [DistributedMonteCarlo.jl](https://github.com/baxmittens/DistributedMonteCarlo.jl)

  A library implementing a Monte Carlo method for integrating memory-heavy objects generated on distributed workers.

- [Ogs6InputFileHandler.jl](https://github.com/baxmittens/Ogs6InputFileHandler.jl) 

  A simple OGS6 input file handler.

- [VTUFileHandler.jl](https://github.com/baxmittens/VTUFileHandler.jl) [@bittens2022vtufilehandler]

  A VTU library for reading and writing vtu files. In addition, all mathematical operators are provided needed for stochastic postprocessing. This results in the datatype `VTUFile` can directly be used with the adaptive sparse grid or in a monte carlo analysis, enabling interpolation and integration for sets of OGS6 results.

- [XDMFFileHandler.jl](https://github.com/baxmittens/XDMFFileHandler.jl)

  Analogous to the above for the XDMF result file format. Provides the datatype `XDMF3File` compatible with stochastic post-processing.


Features of OpenGeoSysUncertaintyQuantification.jl:

- Setup of stochastic OGS6 projects (see [docs](https://baxmittens.github.io/OpenGeoSysUncertaintyQuantification.jl/dev/)).

- Definition of input parameters and (truncated) input distributions via [Distributions.jl](https://github.com/JuliaStats/Distributions.jl).

- Adaptive sparse grid surrogate modeling of the physical state space. All snapshots have to fit in the system memory.

- Distributed Monte Carlo integration. Snapshots do not have to fit in the system memory.

- Monte Carlo integrated Sobol indices.

- Monte Carlo or Latin Hypercube integrated Morris means.

- Computation of expected value, variance, or sensitivity indices of complete OGS6 postprocessing results.

To enable the stochastic postprocessing of large data sets, special attention was paid to implement allocation free in-place variants of all necessary math operators for all output datatypes such as a `VTUFile` or `XDMF3File`.


# Acknowledgements

The author would like to acknowledge the `Bundesanstalt für Geowissenschaften und Rohstoffe` (Federal Institute for Geosciences and Natural Resources, [BGR](https://www.bgr.bund.de/EN/)) for distributing time and resources for the development of this software project.

# References
