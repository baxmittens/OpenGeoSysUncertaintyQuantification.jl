AltInplaceOpsInterface.add!(a::Vector{Float64}, b::Vector{Float64}) = a .+= b
AltInplaceOpsInterface.add!(a::Vector{Float64}, b::Float64) = a .+= b 
mul!(a::Vector{Float64}, b::Float64) = a .*= b
mul!(a::Vector{Float64}, b::Vector{Float64}) = a .*= b
mul!(a::Vector{Float64}, b::Vector{Float64}, c::Float64) = begin; for i = 1:length(a); a[i] = b[i]*c; end; return nothing; end
AltInplaceOpsInterface.minus!(a::Vector{Float64}, b::Vector{Float64}) = a .-= b
AltInplaceOpsInterface.pow!(a::Vector{Float64}, b::Int64) = a .^= b
AltInplaceOpsInterface.pow!(a::Vector{Float64}, b::Float64) = a .^= b

Base.fill!(a::Vector{Vector{Float64}}, b::Float64) = foreach(x->fill!(x,b), a)
Base.similar(a::Vector{Vector{Float64}}) = map(x->similar(x),a)
Base.zero(a::Vector{Vector{Float64}}) = map(zero,a)

AltInplaceOpsInterface.add!(a::Vector{Vector{Float64}}, b::Vector{Vector{Float64}}) = a .+= b
AltInplaceOpsInterface.add!(a::Vector{Vector{Float64}}, b::Float64) = begin; for i = 1:length(a); add!(a[i],b) end; return nothing; end
mul!(a::Vector{Vector{Float64}}, b::Float64) = a .*= b
mul!(a::Vector{Vector{Float64}}, b::Vector{Vector{Float64}}) = begin; for i = 1:length(a); mul!(a[i],b[i]) end; return nothing; end
mul!(a::Vector{Vector{Float64}}, b::Vector{Vector{Float64}}, c::Float64) = begin; for i = 1:length(a); a[i] = b[i].*c; end; return nothing; end
AltInplaceOpsInterface.minus!(a::Vector{Vector{Float64}}, b::Vector{Vector{Float64}}) = a .-= b
AltInplaceOpsInterface.pow!(a::Vector{Vector{Float64}}, b::Int64) = a .^= b
AltInplaceOpsInterface.pow!(a::Vector{Vector{Float64}}, b::Float64) = begin; for i = 1:length(a); pow!(a[i],b) end; return nothing; end

AltInplaceOpsInterface.add!(a::Matrix{Float64}, b::Matrix{Float64}) = a .+= b
AltInplaceOpsInterface.add!(a::Matrix{Float64}, b::Float64) = a .+= b
LinearAlgebra.mul!(a::Matrix{Float64}, b::Float64) = a .*= b
LinearAlgebra.mul!(a::Matrix{Float64}, b::Matrix{Float64}, c::Float64) = begin; for i = 1:length(a); a[i] = b[i]*c; end; return nothing; end
AltInplaceOpsInterface.minus!(a::Matrix{Float64}, b::Matrix{Float64}) = a .-= b
AltInplaceOpsInterface.pow!(a::Matrix{Float64}, b::Int64) = a .^= b
AltInplaceOpsInterface.pow!(a::Matrix{Float64}, b::Float64) = a .^= b

ogs6_modeldef(ogsparams::OGS6ProjectParams) = read(Ogs6ModelDef, ogsparams.projectfile)
ogs6_modeldef(stochparams::StochasticOGSModelParams) = ogs6_modeldef(stochparams.ogsparams)
ogs6_modeldef(ogsuqparams::OGSUQParams) = ogs6_modeldef(ogsuqparams.stochasticmodelparams)
ogs6_modeldef(ogsuq::AbstractOGSUQ) = ogs6_modeldef(ogsuq.ogsuqparams)

ogs6_simcall(ogsparams::OGS6ProjectParams) = ogsparams.simcall
ogs6_simcall(stochparams::StochasticOGSModelParams) = ogs6_simcall(stochparams.ogsparams)
ogs6_simcall(ogsuqparams::OGSUQParams) = ogs6_simcall(ogsuqparams.stochasticmodelparams)
ogs6_simcall(ogsuq::AbstractOGSUQ) = ogs6_simcall(ogsuq.ogsuqparams)

ogs6_outputpath(ogsparams::OGS6ProjectParams) = ogsparams.outputpath
ogs6_outputpath(stochparams::StochasticOGSModelParams) = ogs6_outputpath(stochparams.ogsparams)
ogs6_outputpath(ogsuqparams::OGSUQParams) = ogs6_outputpath(ogsuqparams.stochasticmodelparams)
ogs6_outputpath(ogsuq::AbstractOGSUQ) = ogs6_outputpath(ogsuq.ogsuqparams)

ogs6_additionalprojecfilespath(ogsparams::OGS6ProjectParams) = ogsparams.additionalprojecfilespath
ogs6_additionalprojecfilespath(stochparams::StochasticOGSModelParams) = ogs6_additionalprojecfilespath(stochparams.ogsparams)
ogs6_additionalprojecfilespath(ogsuqparams::OGSUQParams) = ogs6_additionalprojecfilespath(ogsuqparams.stochasticmodelparams)
ogs6_additionalprojecfilespath(ogsuq::AbstractOGSUQ) = ogs6_additionalprojecfilespath(ogsuq.ogsuqparams)

ogs6_postprocfiles(stogsparamsochparams::OGS6ProjectParams) = ogsparams.postprocfiles
ogs6_postprocfiles(stochparams::StochasticOGSModelParams) = ogs6_postprocfiles(stochparams.ogsparams)
ogs6_postprocfiles(ogsuqparams::OGSUQParams) = ogs6_postprocfiles(ogsuqparams.stochasticmodelparams)
ogs6_postprocfiles(ogsuq::AbstractOGSUQ) = ogs6_postprocfiles(ogsuq.ogsuqparams)

stoch_parameters(stochasticmodelparams::StochasticOGSModelParams) = stochasticmodelparams.stochparams
stoch_parameters(ogsuqparams::OGSUQParams) = stoch_parameters(ogsuqparams.stochasticmodelparams)
stoch_parameters(ogsuq::AbstractOGSUQ) = stoch_parameters(ogsuq.ogsuqparams)

stoch_samplemethod(stochasticmodelparams::StochasticOGSModelParams) = stochasticmodelparams.samplemethod
stoch_samplemethod(ogsuqparams::OGSUQParams) = stoch_samplemethod(ogsuqparams.stochasticmodelparams)
stoch_samplemethod(ogsuq::AbstractOGSUQ) = stoch_samplemethod(ogsuq.ogsuqparams)