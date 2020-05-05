using AlgoTuner
include("Algorithm.jl")

# function GetBestKnownValues()
#     instances = ["data/C1_2_9.TXT","data/C2_2_4.TXT",
#                 "data/R1_2_7.TXT","data/R2_2_3.TXT"]
#     bestKnown = Dict{String,Float64}()
#     for inst in instances
#         bestKnown[inst] = VRPTW(1234,inst,300,true,4,15,15,(5,30),1,10,2)
#     end
#     return instances,bestKnown
# end

# benchmark,bestKnown = GetBestKnownValues()

VRPTW_Tuner(seed,instance,tenure,I,operatorRandomness) =
        (VRPTW(seed,instance,300,true,tenure,I,15,(5,30),1,operatorRandomness,2) - bestKnown[instance])/bestKnown[instance]

cmd = AlgoTuner.createRuntimeCommand(VRPTW_Tuner)

AlgoTuner.addIntParam(cmd,"tenure",1,10)
AlgoTuner.addIntParam(cmd,"I",5,15)
AlgoTuner.addIntParam(cmd,"operatorRandomness",5,20)

AlgoTuner.tune(cmd,benchmark,14400,2,[1234,5473],AlgoTuner.ShowAll)



#
# Random.seed!(2)
# test = [1,2,3,4,5]
# test = shuffle!(test)
