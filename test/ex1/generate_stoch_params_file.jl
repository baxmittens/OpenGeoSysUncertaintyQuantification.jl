using OpenGeoSysUncertaintyQuantification

projectfile="./project/point_heat_source_2D.prj"
pathes = generatePossibleStochasticParameters(projectfile)

porosity_ind = findfirst(x->contains(x,"@id/0") && contains(x,"porosity"), pathes)
liquid_th_cond_ind = findfirst(x->contains(x,"@id/0") && contains(x,"AqueousLiquid") && contains(x,"thermal_conductivity"), pathes)

writeStochasticParameters(pathes[[porosity_ind, liquid_th_cond_ind]], "./StochasticParameters.xml")
