---
title: 'DistributedSparseGrids.jl: A Julia library implementing an Adaptive Sparse Grid collocation method'
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

Numerical integration or interpolation of high-dimensional functions is subject to the curse of dimensionality on full tensor grids. One remedy to this problem is sparse grid approximations. The additional construction effort is often worth spending, especially for underlying functions whose evaluation is time-consuming. In the following, a Julia implementation of a local Lagrangian adaptive hierarchical sparse grid collocation method is presented, which is suitable for memory-heavy objects generated on distributed workers.

# Statement of need


# References
