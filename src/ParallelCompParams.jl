import Printf.@sprintf
using Distributed

mutable struct ParallelCompParams
	possible_worker::Vector{Tuple{String,Int}}
	available_worker::Vector{Tuple{String,Int}}	
	worker_ids::Vector{Int}
end

begin
	local const_n_per_worker = 65
	local possible_workers = [
	("ogs04",const_n_per_worker),
	("ogs05",const_n_per_worker),
	("ogs06",const_n_per_worker)
	]
function Standard_ParallelCompParams(parallcomp=true,_const_n_per_worker=80,possible_workers=possible_workers)
	parallcomp ? nps1 = addprocs(floor(Int,_const_n_per_worker-1), restrict=false, topology=:master_worker) : nps1=0
	@info("added $(length(nps1)) local workers")
	remote_machines = check_status(possible_workers)	
	@info("adding $_const_n_per_worker workers per remote server...")
	parallcomp ? nps2 = addprocs(remote_machines,dir="/home/bittens",exename="julia",tunnel=true,topology=:master_worker) : nothing
	@info("done. $(length(procs())) worker available in total")
	return ParallelCompParams(possible_workers,remote_machines,procs())
end
end

function ParallelCompParams(num_local_workers::Int,remote_workers::Vector{Tuple{String,Int}})
	nps1 = addprocs(floor(Int,num_local_workers-1), restrict=false, topology=:master_worker)
	@info("added $(length(nps1)) local workers")
	remote_machines = check_status(remote_workers)
	if !isempty(remote_machines)
		@info("adding $(sum(map(x->x[2],remote_machines))) remote workers")
		addprocs(remote_machines,dir="/home/bittens",exename="julia",tunnel=true,topology=:master_worker) : nothing
	end
	@info("done")
	return ParallelCompParams(remote_workers,remote_machines,procs())
end

function check_cluster_status(possible_workers)
	@info("checking remote server")
	avail_workers = Dict{String,Int}()
	for w in possible_workers
		#if success(`ping -c 1 -t 1 $w`)
			#info(@sprintf("% 12s -> up\n",w))
			if !haskey(avail_workers,String(w))
				avail_workers[String(w)]=1
			else
				num = avail_workers[String(w)]
				avail_workers[String(w)]=num+1
			end
		#else
			#info(@sprintf("% 12s -> down\n",w))
		#end
	end
	return [(w,i) for (w,i) in avail_workers]
end

function check_status(possible_workers)
	@info("checking remote server")
	avail_workers = Tuple{String,Any}[]
	for (w,numprocs) in possible_workers
		if success(`ping -c 1 -t 1 $w`)
			@info(@sprintf("% 12s -> up\n",w))
			push!(avail_workers,(w,numprocs))
		else
			@info(@sprintf("% 12s -> down\n",w))
		end
	end
	return avail_workers
end

mutable struct WorkerInfo
	host::String
	cores::Int
	cpu::String
	worker_ids::Vector{Int}
	memory::Float64
	users::Vector{String}
	usage::Float64
end

cluster_info(hpc::ParallelCompParams) = cluster_info(hpc.worker_ids)
function cluster_info(worker_ids)
	@info("Gathering cluster information")
	ret = Dict{String,WorkerInfo}()
	for w in worker_ids
		host = remotecall_fetch(gethostname,w)
		cores = remotecall_fetch(()-> length(Sys.cpu_info()),w)
		cpu = remotecall_fetch(()->replace(readchomp(pipeline(`cat /proc/cpuinfo`,`grep 'model name'`,`head -1`)), "model name\t: "=>""),w)
		mem = remotecall_fetch(()->parse(Int,replace(replace(replace(readchomp(pipeline(`cat /proc/meminfo`,`grep MemTotal`)), "MemTotal:"=>""),"kB"=>""), " "=>""))/1e6,w)
		users = remotecall_fetch(()->readchomp(`users`),w)
		usage = remotecall_fetch(()->100 - parse(Float64,readchomp(pipeline(`vmstat`,`tail -1`,`awk '{print $15}'`)) ),w)
		if !haskey(ret,host)
			ret[host] = WorkerInfo(host,cores,cpu,[w],mem,split(users,' '),usage)
		else
			wi = ret[host]
			push!(wi.worker_ids,w)
		end
	end
	util = 0.0
	ram = 0.0
	for (w,wi) in ret
		wutil = wi.usage
		wmem = wi.memory
		#info(@sprintf("% 12s provides % 4d cores\n\t\t%s\n\t\twith % 4d GB RAM\n\t\tUsers logged in: %s\n\t\tCPU utilization: % 4.0f%%\n", w, fetch(c[1]), fetch(c[2]), wmem, fetch(c[4]), wutil) )
		util += wutil
		ram += wmem
	end
	@info("Total RAM: "*@sprintf("%.1f",ram)*" GB")
	@info("Cluster utilization: "*string(util/nworkers())*"%")
	return ret
end


