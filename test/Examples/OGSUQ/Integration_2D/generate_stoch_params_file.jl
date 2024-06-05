using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
OGS_PRJ_PATH = joinpath(OpenGeoSysUncertaintyQuantification.ogs_prj_folder(), "Saturated_Mass_Transport")
projectfile= joinpath(OGS_PRJ_PATH,"prj","DiffusionAndStorageAndAdvectionAndDispersionHalf.prj")
output_xml = joinpath(PATH, "StochasticParameters.xml")

pathes = generatePossibleStochasticParameters(projectfile, output_xml)

ind_1 = findfirst(x->contains(x,"@id/0") && contains(x,"longitudinal_dispersivity"), pathes)
ind_2 = findfirst(x->contains(x,"@id/0") && contains(x,"transversal_dispersivity"), pathes)

writeStochasticParameters(pathes[[ind_1, ind_2]], output_xml)
