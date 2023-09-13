using DecqedMesher
using Test

@testset "3D Primal Mesh" begin

    # the test 3D mesh file is "3D_testmesh.msh"
    primalmesh, physicalnames_dict, all_entities_struct = DecqedMesher.Mesher3D_Primalmesh.complete_primalmesh("/meshes/3D_testmesh.msh") 

    # checking primalmesh
    # checking primal node whose id is 1
    testnode = primalmesh.nodedict[1]
    @test testnode.id == 1
    @test testnode.coords == [-0.5, -0.5, 0.5]
    @test testnode.root_entitydim == 0
    @test testnode.root_entityid == 1
    # the following entity info is correct: curve tags: 1, 4, 9; surface tags: 1, 3, 5; volume tags: 1
    @test testnode.entities_dict == Dict{Int64, Vector}(1 => Any[1, 4, 9], 2 => Any[1, 3, 5], 3 => Any[1])

    # checking physicalnames_dict
    # there should be no physical entities assigned any physical names, so the dict of physical names is empty
    @test physicalnames_dict == Dict{Int64, DecqedMesher.Mesher3D_Types.Physicalname_struct}()

    # checking all_entities_struct
    # checking curve entity whose id is 5
    @test all_entities_struct.curve_entities_dict[5].physicaltags == [5]
    @test all_entities_struct.curve_entities_dict[5].boundingpoints == [5, 6]

end

@testset "3D Dual Mesh" begin

    @test 1 == 1

end

