using .DecqedMesher
using Test


using .Mesher3D_Parse
@testset "Parsing" begin
    
    @test Mesher3D_Parse.getfilepath("/meshes/transfinite_test.msh") == "/Users/RichardLi/Desktop/QURIP/qurip_code/DecqedMesher.jl/meshes/transfinite_test.msh"

end
