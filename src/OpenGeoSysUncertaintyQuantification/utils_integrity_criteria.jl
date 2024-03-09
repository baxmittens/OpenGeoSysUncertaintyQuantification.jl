function principle_stress_S3(sigma)
	tmpmat = zeros(Float64,3,3)
	si,sj = size(sigma)[2:3]
	retvals = Matrix{Float64}(undef,si,sj)
	for i = 1:si, j = 1:sj
		tmpmat[1,1] = sigma[1,i,j]
		tmpmat[1,2] = sigma[4,i,j]
		tmpmat[2,1] = sigma[4,i,j]
		tmpmat[2,2] = sigma[2,i,j]
		tmpmat[3,3] = sigma[3,i,j]
		vals = eigvals(tmpmat)
		retvals[i,j] = vals[3]
	end
	return retvals
end 

function principle_stresses(sigma)
	tmpmat = zeros(Float64,3,3)
	si,sj = size(sigma)[2:3]
	retvals1 = Matrix{Float64}(undef,si,sj)
	retvals2 = Matrix{Float64}(undef,si,sj)
	retvals3 = Matrix{Float64}(undef,si,sj)
	for i = 1:si, j = 1:sj
		tmpmat[1,1] = sigma[1,i,j]
		tmpmat[1,2] = sigma[4,i,j]
		tmpmat[2,1] = sigma[4,i,j]
		tmpmat[2,2] = sigma[2,i,j]
		tmpmat[3,3] = sigma[3,i,j]
		vals = eigvals(tmpmat)
		retvals1[i,j] = vals[1]
		retvals2[i,j] = vals[2]
		retvals3[i,j] = vals[3]
	end
	return retvals1,retvals2,retvals3
end 

function diletancy_crit(effsig1,effsig3,c,phi)
	r = effsig1 .- effsig3
	R = (effsig1 .+ effsig3).*sin(phi) .- 2.0.*c*cos(phi)
	#r = (effsig3 .- effsig1)./2.0
	#R = c*cos(phi) .- (effsig3 .+ effsig1)./2.0.*sin(phi)
	dilat = 2.0*r./R
	return dilat
end
function diletancy_max_crit(effsig1,effsig3,c,phi)
	dilat = diletancy_crit(effsig1,effsig3,c,phi)
	return vec(maximum(dilat[:,2:end],dims=2))
end
function fluid_max_crit(effsig3)
	return vec(maximum(effsig3[:,2:end],dims=2))
end
function temp_max_crit(temp)
	temp_crit = temp ./ 373.15
	return vec(maximum(temp_crit[:,2:end],dims=2))
end
function diletancy_maxΔ_crit(effsig1,effsig3,c,phi)
	dilat = diletancy_crit(effsig1,effsig3,c,phi)
	dilat = dilat .- dilat[:,2]
	return vec(maximum(dilat[:,2:end],dims=2))
end
function fluid_maxΔ_crit(effsig3)
	_effsig3 = effsig3 .- effsig3[:,2]
	return vec(maximum(_effsig3[:,2:end],dims=2))
end
function temp_maxΔ_crit(temp)
	temp_crit = temp ./ 373.15
	temp_crit = temp_crit .- temp_crit[:,2]
	return vec(maximum(temp_crit[:,2:end],dims=2))
end
function diletancy_ini_crit(effsig1,effsig3,c,phi)
	dilat = diletancy_crit(effsig1,effsig3,c,phi)
	return dilat[:,2]
end
function fluid_ini_crit(effsig3)
	return effsig3[:,2]
end
function temp_ini_crit(temp)
	temp_crit = temp ./ 373.15
	return temp_crit[:,2]
end