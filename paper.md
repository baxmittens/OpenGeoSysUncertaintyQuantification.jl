---
title: 'OGSUQ.jl: a Julia library implementing an uncertainty quantification toolbox for OpenGeoSys'
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

In simulation-aided design of saftey-related projects, the effects of uncertainties in the input parameters on the outcome are often of great interest. [OpenGeoSys 6](https://www.opengeosys.org/) (OGS6) is an open-source scientific project for the simulation of thermo-hdydro-mechanical (THM) processes in porous media. Various parameters are needed for this kind of complex coupled simulation, many of which are subject to uncertainty due to imprecise knowledge. [OGSUQ.jl](https://github.com/baxmittens/OGSUQ.jl) is a Julia library which provides all the necessary methods to quantify uncertainties in a validly configured deterministic OGS6 modell.

# Statement of need

Stability verifications for large structures can often only be carried out with the help of numerical simulations. A particularly difficult example is the safe storage of highly radioactive waste in subsurface repositories. These are usually planned at depths of several hundred meters. The heat radiated by the fuel rods can influence thermal-hydraulic-mechanical processes down to depths of several kilometers. Numerical simulations are needed to ensure site safety. Because of the outstanding interest in the safety of these repositories, the uncertainties are also given special attention.

Parameterizing a THM model in OpenGeoSys [@kolditz2012opengeosys] is complex and time-consuming due to the large number of possible input parameters. For easier applicability, the decision was made not to design this package as a generic uncertainty quantification framework, but to relate it explicitly to OGS6. Nevertheless, care was taken to ensure that the underlying packages are as generic as possible and can be used in other projects. 

The OpenGeoSys community commonly uses Python, however for this project Julia was chosen due to its superior efficiency and built-in capabilities for distributive computing.

To this date, there is no uncertainty quantification toolbox for OpenGeoSys, neither in Python nor in the Julia language. 

# Features

Most of all functionalities of this package are outsourced into independent julia packages to maintain their generic character. Therefore, OGSUQ.jl serves as an umbrella project for the following projects:

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


Features added within OGSUQ.jl:

- Setup of stochastic OGS6 projects (see [docs](https://baxmittens.github.io/OGSUQ.jl/dev/)).

- Definition of input parameters and (truncated) input distributions via [Distributions.jl](https://github.com/JuliaStats/Distributions.jl).

- Computation of expected value and variance

# Further development

The next steps in the further development are primarily related to stochastic postprocessing and the representation thereof. Two examples are confidence intervals and the meaningful reduction of high-dimensional results. 

# Acknowledgements

The author would like to acknowledge the `Bundesanstalt für Geowissenschaften und Rohstoffe` (Federal Institute for Geosciences and Natural Resources, [BGR](https://www.bgr.bund.de/EN/)) for distributing time and resources for the development of this software project.

# References
