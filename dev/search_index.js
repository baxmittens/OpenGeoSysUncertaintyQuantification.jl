var documenterSearchIndex = {"docs":
[{"location":"lib/lib/#Library","page":"Library","title":"Library","text":"","category":"section"},{"location":"lib/lib/#Contents","page":"Library","title":"Contents","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"Pages = [\"lib.md\"]\nDepth = 4","category":"page"},{"location":"lib/lib/#Functions","page":"Library","title":"Functions","text":"","category":"section"},{"location":"lib/lib/#Index","page":"Library","title":"Index","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"Pages = [\"lib.md\"]","category":"page"},{"location":"lib/lib/#Typedefs","page":"Library","title":"Typedefs","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"DistributedSparseGrids.AbstractSparseGrid\nDistributedSparseGrids.AbstractHierarchicalSparseGrid\nDistributedSparseGrids.PointDict","category":"page"},{"location":"lib/lib/#Structs","page":"Library","title":"Structs","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"DistributedSparseGrids.CollocationPoint\nDistributedSparseGrids.HierarchicalCollocationPoint\nDistributedSparseGrids.AdaptiveHierarchicalSparseGrid","category":"page"},{"location":"lib/lib/#General-functions","page":"Library","title":"General functions","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"init\ninterpolate\nintegrate\ninit_weights!\ninit_weights_inplace_ops!\ndistributed_init_weights!\ndistributed_init_weights_inplace_ops!\ngenerate_next_level!","category":"page"},{"location":"lib/lib/#Utils","page":"Library","title":"Utils","text":"","category":"section"},{"location":"lib/lib/","page":"Library","title":"Library","text":"DistributedSparseGrids.AHSG","category":"page"},{"location":"#OGSUQ.jl","page":"Home","title":"OGSUQ.jl","text":"","category":"section"},{"location":"#Contents","page":"Home","title":"Contents","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Pages = [\"index.md\"]\nDepth = 5","category":"page"},{"location":"#The-principle-idea-for-the-creation-of-a-stochastic-OGS6-project","page":"Home","title":"The principle idea for the creation of a stochastic OGS6 project","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The principle idea is to always start with a fully configured and running deterministic OGS6 project. There are three basic functions which create three individual xml-files which are used to define the stochastic OGS project. These files are human-readable and can be manually configured and duplicated for the use in other, or slightly altered, stochastic projects.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The first function ","category":"page"},{"location":"","page":"Home","title":"Home","text":"generatePossibleStochasticParameters(\n\tprojectfile::String, \n\tfile::String=\"./PossibleStochasticParameters.xml\", \n\tkeywords::Vector{String}=ogs_numeric_keyvals\n\t)","category":"page"},{"location":"","page":"Home","title":"Home","text":"scans an existing projectfile for all parameters which can be used in a stochastic project. What is considered to be a possible stochastic parameter is defined by the keywords. By this, an xml-file file is generated where all possible stochastic parameters are listed. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"The second function","category":"page"},{"location":"","page":"Home","title":"Home","text":"generateStochasticOGSModell(\n\tprojectfile::String,\n\tsimcall::String,\n\tadditionalprojecfilespath::String,\n\tpostprocfile::Vector{String},\n\tstochpathes::Vector{String},\n\toutputpath=\"./Res\",\n\tstochmethod=AdaptiveHierarchicalSparseGrid,\n\tn_local_workers=50,\n\tkeywords=ogs_numeric_keyvals,\n\tsogsfile=\"StochasticOGSModelParams.xml\"\n\t)","category":"page"},{"location":"","page":"Home","title":"Home","text":"creates an xml-file which defines the so-called StochasticOGSModelParams. It is defined by ","category":"page"},{"location":"","page":"Home","title":"Home","text":"the location to the existing projectfile, \nthe simcall (e.g. \"path/to/ogs/bin/ogs\"), \na additionalprojecfilespath where meshes and other files can be located which are copied in each individual folder for a OGS6-snapshot, \nthe path to one or more postprocfiles, \nthe stochpathes, generated with generatePossibleStochasticParameters, manipulated by the user, and loaded by the loadStochasticParameters-function,\nan outputpath, where all snapshots will be stored,\na stochmethod (Sparse grid or Monte-Carlo, where Monte-Carlo is not yet implemented),\nthe number of local workers n_local_workers, and, \nthe filename sogsfile under which the model is stored as an xml-file. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"This function also creates a file user_function.jl which is loaded by all workers and serves as an interface between OGS6 and Julia. Here it is defined how the individual snaptshots are generated and how the postprocessing results are handled.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The third and last function","category":"page"},{"location":"","page":"Home","title":"Home","text":"generateSampleMethodModel(\n\tsogsfile::String, \n\tanafile=\"SampleMethodParams.xml\"\n\t)\n# or\ngenerateSampleMethodModel(\n\tsogs::StochasticOGSModelParams, \n\tanafile=\"SampleMethodParams.xml\"\n\t)","category":"page"},{"location":"","page":"Home","title":"Home","text":"creates an xml-file anafile with all necessary parameters for the chosen sample method in the StochasticOGSModelParams.","category":"page"},{"location":"#Usage","page":"Home","title":"Usage","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"In this chapter, Example 1 is used to illustrate the workflow. The underlying deterministic OGS6 project is the point heat source example (Thermo-Richards-Mechanics project files).","category":"page"},{"location":"#Defining-the-stochastic-dimensions","page":"Home","title":"Defining the stochastic dimensions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The following lines of code ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using OGSUQ\nprojectfile=\"./project/point_heat_source_2D.prj\"\npathes = generatePossibleStochasticParameters(projectfile)","category":"page"},{"location":"","page":"Home","title":"Home","text":"return an array of strings with OGS6-XML-pathes and generates an XML-file PossibleStochasticParameters.xml in the working directory","category":"page"},{"location":"","page":"Home","title":"Home","text":"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Array\n\t julia:type=\"String,1\"\n>\n\t./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?specific_heat_capacity/value\n\t./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value\n\t\t\t.\n\t\t\t.\n\t\t\t.\n\t./parameters/parameter/?displacement0/values\n\t./parameters/parameter/?pressure_ic/values\n</Array>","category":"page"},{"location":"","page":"Home","title":"Home","text":"where all parameters possible to select as stochastic parameter are mapped. Since, in this example, an adaptive sparse grid collocation sampling shall be adopted, only two parameters, the porosity and the thermal conductivity of the aqueous liquid,","category":"page"},{"location":"","page":"Home","title":"Home","text":"./media/medium/@id/0/properties/property/?porosity/value\n./media/medium/@id/0/phases/phase/?AqueousLiquid/properties/property/?thermal_conductivity/value","category":"page"},{"location":"","page":"Home","title":"Home","text":"are selected. Thus, all other parameters are deleted from the file. The resulting xml-file is stored as altered_PossibleStochasticParameters.xml in the working directory.","category":"page"},{"location":"#Defining-the-stochastic-model","page":"Home","title":"Defining the stochastic model","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The following code snippet ","category":"page"},{"location":"","page":"Home","title":"Home","text":"using OGSUQ\nprojectfile=\"./project/point_heat_source_2D.prj\"\nsimcall=\"/path/to/ogs/bin/ogs\"\nadditionalprojecfilespath=\"./mesh\"\noutputpath=\"./Res\"\npostprocfiles=[\"PointHeatSource_ts_10_t_50000.000000.vtu\"]\noutputpath=\"./Res\"\nstochmethod=AdaptiveHierarchicalSparseGrid\nn_local_workers=50\n\nstochparampathes = loadStochasticParameters(\"altered_PossibleStochasticParameters.xml\")\n\t\nstochasticmodelparams = generateStochasticOGSModell(\n\tprojectfile,\n\tsimcall,\n\tadditionalprojecfilespath,\n\tpostprocfiles,\n\tstochparampathes,\n\toutputpath,\n\tstochmethod,\n\tn_local_workers) # generate the StochasticOGSModelParams\n\nsamplemethodparams = generateSampleMethodModel(stochasticmodelparams) # generate the SampleMethodParams","category":"page"},{"location":"","page":"Home","title":"Home","text":"generates two XML-files, StochasticOGSModelParams.xml and SampleMethodParams.xml, defining the stochastic model.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Again, these files are altered and stored under altered_StochasticOGSModelParams.xml and altered_SampleMethodParams.xml.","category":"page"},{"location":"","page":"Home","title":"Home","text":"In the former, the two stochastic parameters are altered. The probability distribution of the porosity is changed from Uniform to Normal with mean μ=0.375 and standard deviation σ=0.1.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<StochasticOGS6Parameter\n\t path=\"./media/medium/@id/0/properties/property/?porosity/value\"\n\t valspec=\"1\"\n\t lower_bound=\"0.15\"\n\t upper_bound=\"0.60\"\n>\n\t<Normal\n\t\t julia:type=\"Float64\"\n\t\t julia:fieldname=\"dist\"\n\t\t μ=\"0.375\"\n\t\t σ=\"0.1\"\n\t/>\n</StochasticOGS6Parameter>","category":"page"},{"location":"","page":"Home","title":"Home","text":"Note that for efficiency, the normal distribution is changed to a truncated normal distribution by the parameters lower_bound=0.15 and upper_bound=0.60. This results in an integration error of approximately 2.5% for this example. See the picture below for a visualization of the normal distribution mathcalN and the truncated normal distribution barmathcalN.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<p align=\"center\">\n\t<img src=\"https://user-images.githubusercontent.com/100423479/223678210-58ebf8c4-731a-4a5e-9037-693f80d431b4.png\" width=\"350\" height=\"350\" />\n</p>","category":"page"},{"location":"","page":"Home","title":"Home","text":"The second parameter, the thermal conductivity, is set up as a truncated normal distribution with mean μ=0.6, standard deviation σ=0.05, lower_bound=0.5, and, upper_bound=0.7. The multivariate truncated normal distribution resulting from the convolution of both one-dimensional distributions is pictured below. Note, that the distribution has been transformed to the domain -11^2 of the sparse grid.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<p align=\"center\">\n\t<img src=\"https://user-images.githubusercontent.com/100423479/223682880-2be481cc-986a-4f00-a47a-042d0b0684e5.png\" width=\"400\" height=\"250\" />\n</p>","category":"page"},{"location":"","page":"Home","title":"Home","text":"The second file altered_SampleMethodParams.xml defines the sample method parameters such as","category":"page"},{"location":"","page":"Home","title":"Home","text":"the number of dimensions N=2,\nthe return type RT=\"VTUFile\" (see VTUFileHandler.jl)\nthe number of initial hierachical level of the sparse grid init_lvl=4,\nthe number of maximal hierarchical level of the sparse grid maxlvl=20, and,\nthe minimum hierarchical surplus for the adaptive refinement tol=0.01.","category":"page"},{"location":"#Sampling-the-model","page":"Home","title":"Sampling the model","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The following lines of code","category":"page"},{"location":"","page":"Home","title":"Home","text":"using OGSUQ\nogsuqparams = OGSUQParams(\"altered_StochasticOGSModelParams.xml\", \"altered_SampleMethodParams.xml\")\nogsuqasg = OGSUQ.init(ogsuqparams)\nOGSUQ.start!(ogsuqasg)","category":"page"},{"location":"","page":"Home","title":"Home","text":"load the parameters ogsuqparams, initializes the model ogsuqasg, and, starts the sampling procedure. Finally the expected value is integrated.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Initializing the model OGSUQ.init(ogsuqparams) consists of two steps","category":"page"},{"location":"","page":"Home","title":"Home","text":"1. Adding all local workers (in this case 50 local workers)\n2. Initializing the adaptive sparse grid.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Starting the sampling procedure OGSUQ.start!(ogsuqasg) first creates 4 initial hierarchical levels levels and, subsequently, starts the adaptive refinement. This first stage results in an so-called surrogate model of the physical domain defined by the boundaries of the stochastic parameters","category":"page"},{"location":"","page":"Home","title":"Home","text":"<table border=\"0\"><tr>\n<td> \n\t<figure>\n\t\t<img src=\"https://user-images.githubusercontent.com/100423479/223154558-4b94d7a2-e93b-45ef-9783-11437ae23b35.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>resulting sparse grid</em></figcaption>\n\t</figure>\n</td>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/response_surface.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>response surface</em></figcaption>\n\t</figure>\n</td>\n</tr></table>","category":"page"},{"location":"#Computation-of-the-expected-value","page":"Home","title":"Computation of the expected value","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The expected value of an stochastic OGS project can be computed by:","category":"page"},{"location":"","page":"Home","title":"Home","text":"import VTUFileHandler\nexpval,asg_expval = OGSUQ.𝔼(ogsuqasg);\nVTUFileHandler.rename!(expval,\"expval_heatpointsource.vtu\")\nwrite(expval)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Hereby, the physical surrogate model, generated by the sampling of the model, is weighted against the pdf of each stochastic dimension. The resulting sparse grid and the response function (by taking the LinearAlgebra.norm(::VTUFile)) can be seen below.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<table border=\"0\"><tr>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/asg_expval.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>resulting sparse grid</em></figcaption>\n\t</figure>\n</td>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/response_surface_expval.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>response surface</em></figcaption>\n\t</figure>\n</td>\n</tr></table>","category":"page"},{"location":"","page":"Home","title":"Home","text":"By integrating over the domain the expected value is computed. Below the pressure field and the temperature field are shown.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<table border=\"0\"><tr>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/expval_press.PNG\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>expected value: pressure field</em></figcaption>\n\t</figure>\n</td>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/expval_temp.PNG\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>expected value: temperature field</em></figcaption>\n\t</figure>\n</td>\n</tr></table>","category":"page"},{"location":"#Computation-of-the-variance","page":"Home","title":"Computation of the variance","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The variance can be computed by:","category":"page"},{"location":"","page":"Home","title":"Home","text":"varval,asg_varval = OGSUQ.var(ogsuqasg,expval);\nVTUFileHandler.rename!(varval,\"varval_heatpointsource.vtu\")\nwrite(varval)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Again, the physical surrogate is used to compute the variance on another sparse grid. Below the resulting sparse grid and the response function is displayed. Note that despite the complexity of the response function, it is captured efficiently by the adaptive sparse grid.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<table border=\"0\"><tr>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/asg_varval.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>resulting sparse grid</em></figcaption>\n\t</figure>\n</td>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/response_surface_varval.png\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>response surface</em></figcaption>\n\t</figure>\n</td>\n</tr></table>","category":"page"},{"location":"","page":"Home","title":"Home","text":"As above, the variance can be computed by integrating over the stochastic domain. Below the variance of the pressure field and temperature field is displayed. ","category":"page"},{"location":"","page":"Home","title":"Home","text":"<table border=\"0\"><tr>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/varval_press.PNG\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>variance: pressure field</em></figcaption>\n\t</figure>\n</td>\n<td> \n\t<figure>\n\t\t<img src=\"./assets/varval_temp.PNG\" width=\"350\" height=\"300\" /><br>\n\t\t<figcaption><em>variance: temperature field</em></figcaption>\n\t</figure>\n</td>\n</tr></table>","category":"page"},{"location":"#Contributions,-report-bugs-and-support","page":"Home","title":"Contributions, report bugs and support","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Contributions to or questions about this project are welcome. Feel free to create a issue or a pull request on GitHub.","category":"page"}]
}
