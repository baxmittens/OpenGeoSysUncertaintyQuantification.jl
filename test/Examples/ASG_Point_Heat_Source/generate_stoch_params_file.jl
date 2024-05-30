using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
projectfile = joinpath(PATH, "project", "point_heat_source_2D.prj")
output_xml = joinpath(PATH, "StochasticParameters.xml")

pathes = generatePossibleStochasticParameters(projectfile, output_xml)

porosity_ind = findfirst(x->contains(x,"@id/0") && contains(x,"porosity"), pathes)
liquid_th_cond_ind = findfirst(x->contains(x,"@id/0") && contains(x,"AqueousLiquid") && contains(x,"thermal_conductivity"), pathes)

writeStochasticParameters(pathes[[porosity_ind, liquid_th_cond_ind]], output_xml)
