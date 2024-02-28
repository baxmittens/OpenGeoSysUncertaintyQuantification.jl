import OpenGeoSysUncertaintyQuantification
ogsuqparams = OpenGeoSysUncertaintyQuantification.OGSUQParams("altered_StochasticOGSModelParams.xml", "altered_SampleMethodParams.xml")
ogsuqasg = OpenGeoSysUncertaintyQuantification.init(ogsuqparams)
OpenGeoSysUncertaintyQuantification.start!(ogsuqasg)
expval,asg_expval = OpenGeoSysUncertaintyQuantification.𝔼(ogsuqasg)
expval,asg_expval = OpenGeoSysUncertaintyQuantification.var(ogsuqasg)