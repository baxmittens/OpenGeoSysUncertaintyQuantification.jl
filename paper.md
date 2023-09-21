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




[@kolditz2012opengeosys]

# References
