using OpenGeoSysUncertaintyQuantification

PATH = joinpath(splitpath(@__FILE__)[1:end-1]...)
OGS_PRJ_PATH = joinpath(OpenGeoSysUncertaintyQuantification.ogs_prj_folder(), "Saturated_Mass_Transport")
projectfile= joinpath(OGS_PRJ_PATH,"prj","DiffusionAndStorageAndAdvectionAndDispersionHalf.prj")
output_xml = joinpath(PATH, "StochasticParameters.xml")

pathes = generatePossibleStochasticParameters(projectfile, output_xml)

#./media/medium/@id/0/properties/property/?longitudinal_dispersivity/value
#./media/medium/@id/0/properties/property/?transversal_dispersivity/value
#./parameters/parameter/?decay/value
#./parameters/parameter/?kappa1/values

ind_1 = findfirst(x->contains(x,"@id/0") && contains(x,"longitudinal_dispersivity"), pathes)
#ind_2 = findfirst(x->contains(x,"@id/0") && contains(x,"transversal_dispersivity"), pathes)
#ind_2 = findfirst(x->contains(x,"parameters") && contains(x,"decay"), pathes)
ind_2 = findfirst(x->contains(x,"parameters") && contains(x,"kappa1"), pathes)

writeStochasticParameters(pathes[[ind_1, ind_2]], output_xml)
