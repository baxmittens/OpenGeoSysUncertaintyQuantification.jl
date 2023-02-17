if !isequal(VERSION,v"1.0.3")
	error("Must be executed on Julia 1.0.3")
end

if Sys.isapple()
    error("Apple not supported.")
elseif Sys.iswindows()
	error("Windows not supported.")
elseif Sys.islinux()
    _my_home = joinpath("/home","bittens");
end

include(joinpath("ParallelCompParams.jl"));