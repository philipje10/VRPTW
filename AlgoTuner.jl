"""The AlgoTuner is adapted from https://github.com/dpacino/AlgoTuner.jl. The AlgoTuner is
licenced under the GNU General Public License v3.0.

Permissions of this strong copyleft license are conditioned on making available complete source
code of licensed works and modifications, which include larger works using a licensed work,
under the same license. Copyright and license notices must be preserved. Contributors provide
an express grant of patent rights."""

using AlgoTuner
include("Algorithm.jl")

function GetBestKnownValues()
    instances = ["data/C1_2_9.TXT","data/C2_2_4.TXT",
                "data/R1_2_7.TXT","data/R2_2_3.TXT"]
    bestKnown = Dict{String,Float64}()
    for inst in instances
        bestKnown[inst] = VRPTW(1234,inst,300,true,4,15,15,(5,30),1,10,2)
    end
    return instances,bestKnown
end

benchmark,bestKnown = GetBestKnownValues()

VRPTW_Tuner(seed,instance,tenure,I,R_operator) =
        (VRPTW(seed,instance,300,true,d,I,15,(5,30),1,R_operator,2) - bestKnown[instance])/bestKnown[instance]

cmd = AlgoTuner.createRuntimeCommand(VRPTW_Tuner)

AlgoTuner.addIntParam(cmd,"d",1,10)
AlgoTuner.addIntParam(cmd,"I",5,15)
AlgoTuner.addIntParam(cmd,"R_operator",1,20)

AlgoTuner.tune(cmd,benchmark,36000,4,[3869,5473,2690,8375],AlgoTuner.ShowAll)
