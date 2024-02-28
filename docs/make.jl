import Pkg; Pkg.add("Documenter")
#Pkg.add("StaticArrays")
#Pkg.add("Colors")
#Pkg.add("PlotlyJS")
#Pkg.add("UnicodePlots")
#Pkg.add("FastGaussQuadrature")
#Pkg.add("ProgressMeter")
#Pkg.add("DistributedSparseGrids")
#Pkg.develop("DistributedSparseGrids")
Pkg.develop(url="https://github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl.git")
#Pkg.develop("OpenGeoSysUncertaintyQuantification")

#push!(LOAD_PATH,"../src/")
#include("../src/DistributedSparseGrids.jl")

using Documenter, OpenGeoSysUncertaintyQuantification
makedocs(
	sitename = "OgsUQ.jl",
	modules = [OpenGeoSysUncertaintyQuantification],
	pages = [
		"Home" => "index.md"
		#"Library" => "lib/lib.md"
	]
	)
deploydocs(
    repo = "github.com/baxmittens/OpenGeoSysUncertaintyQuantification.jl.git"
)


#Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"
#PlotlyJS = "f0f68f2c-4968-5e81-91da-67840de0976a"
#UnicodePlots = "b8865327-cd53-5732-bb35-84acbb429228"
#FastGaussQuadrature = "442a2c76-b920-505d-bb47-c5924d526838"