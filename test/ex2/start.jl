using OGSUQ
ogsuqparams = OGSUQParams("altered_StochasticOGSModelParams.xml", "altered_SampleMethodParams.xml")
ogsuqasg = OGSUQ.init(ogsuqparams)
OGSUQ.start!(ogsuqasg)
expval,asg_expval = OGSUQ.𝔼(ogsuqasg)