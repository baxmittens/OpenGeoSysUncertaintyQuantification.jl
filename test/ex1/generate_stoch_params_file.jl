using OpenGeoSysUncertaintyQuantification

__relpath__ = relpath(@__DIR__, "./")
projectfile = joinpath(__relpath__, "project", "point_heat_source_2D.prj")
output_xml = joinpath(__relpath__, "StochasticParameters.xml")

pathes = generatePossibleStochasticParameters(projectfile)

porosity_ind = findfirst(x->contains(x,"@id/0") && contains(x,"porosity"), pathes)
liquid_th_cond_ind = findfirst(x->contains(x,"@id/0") && contains(x,"AqueousLiquid") && contains(x,"thermal_conductivity"), pathes)

writeStochasticParameters(pathes[[porosity_ind, liquid_th_cond_ind]], output_xml)
