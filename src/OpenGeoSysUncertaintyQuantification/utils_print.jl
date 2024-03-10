import Base.display

function display(io::IO, stochparams::Vector{StochasticOGS6Parameter})
	N = length(stochparams)
	header = ["#","Name", "Dist.", "lower_bound", "upper_bound", "valspec"]
	data = Matrix{Any}(undef, N, 6)
	for (i,stochparam) in enumerate(stochparams)
		data[i,1] = i
		data[i,2] = format_ogs_path(stochparam.path)
		data[i,3] = sprint(show, stochparam.dist)
		data[i,4] = stochparam.lower_bound
		data[i,5] = stochparam.upper_bound
		data[i,6] = stochparam.valspec
	end
	return pretty_table(data; header)
end