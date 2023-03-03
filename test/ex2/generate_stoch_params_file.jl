#include("../../src/OGSUQ.jl")
using OGSUQ

projectfile="./project/point_heat_source_2D.prj"
pathes = generatePossibleStochasticParameters(projectfile)
