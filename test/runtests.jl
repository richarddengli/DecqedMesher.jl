using DecqedMesher
using Test

#########################################################################################
# the test 3D mesh file is "3D_testmesh.msh"
# note the below line will only work when `pkg test`` (or equivalent) is run due to the additional "/test" appended to the front of the file path when testing in this manner
testfile_3D = "/meshes/3D_testmesh.msh"

@testset "mesher3D_parse.jl" begin

    nodedict, tetdict, physicalnames_dict, all_entities_struct = DecqedMesher.Mesher3D_Parse.parsefile(testfile_3D)

    # checking high-level info
    @test length(nodedict) == 45
    @test (length(tetdict)) == 100
    @test physicalnames_dict == Dict{Int64, DecqedMesher.Mesher3D_Types.Physicalname_struct}()
    @test length(all_entities_struct.point_entities_dict) == 8
    @test length(all_entities_struct.curve_entities_dict) == 12
    @test length(all_entities_struct.surface_entities_dict) == 6
    @test length(all_entities_struct.volume_entities_dict) == 1

end

@testset "mesher3D_primalmesh.jl" begin

    primalmesh, physicalnames_dict, all_entities_struct = DecqedMesher.Mesher3D_Primalmesh.complete_primalmesh(testfile_3D)  

    # checking primalmesh
    # checking primal node whose id is 1
    testnode = primalmesh.nodedict[1]
    @test testnode.id == 1
    @test testnode.coords == [-0.5, -0.5, 0.5]
    @test testnode.root_entitydim == 0
    @test testnode.root_entityid == 1
    # the following entity info is correct: curve tags: 1, 4, 9; surface tags: 1, 3, 5; volume tags: 1
    @test testnode.entities_dict == Dict{Int64, Vector}(1 => Any[1, 4, 9], 2 => Any[1, 3, 5], 3 => Any[1])

    # checking primal edge whose id is [24, 45], note support volume is 0 until calculated in "mesher3D_dualmesh.jl"
    testedge = primalmesh.edgedict[[24, 45]]
    @test testedge.id == [24, 45]

    # checking physicalnames_dict
    # there should be no physical entities assigned any physical names, so the dict of physical names is empty
    @test physicalnames_dict == Dict{Int64, DecqedMesher.Mesher3D_Types.Physicalname_struct}()

    # checking all_entities_struct
    # checking curve entity whose id is 5
    @test all_entities_struct.curve_entities_dict[5].physicaltags == [5]
    @test all_entities_struct.curve_entities_dict[5].boundingpoints == [5, 6]

end

@testset "mesher3D_dualmesh.jl" begin

    dualmesh, primalmesh, physicalnames_dict, all_entities_struct = complete_dualmesh(testfile_3D)  

    # checking high-level info
    @test length(dualmesh.dualnodedicts.interior_dualnodedict) == length(primalmesh.tetdict)
    @test length(dualmesh.dualnodedicts.boundary_dualnodedict) == 84
    @test length(dualmesh.dualnodedicts.auxiliary_dualnodedict) == 126

    @test length(dualmesh.dualedgedicts.interior_dualedgedict) + length(dualmesh.dualedgedicts.boundary_dualedgedict) == length(primalmesh.facedict)
    # each boundary primal face has 3 auxiliary_onprimaledge_dualedges
    @test length(dualmesh.dualedgedicts.auxiliary_onprimaledge_dualedgedict) == 3*length(dualmesh.dualnodedicts.boundary_dualnodedict)
    #  each boundary primal face has 3 boundary primal edges, and each boundary primal edge has 2 auxiliary_onprimaledge_dualedges, but each boundary
    # primal edge is shared between exactly 2 boundary primal faces, thus (# auxiliary_onprimalface_dualedges)/(# boundary primal faces) = 3*2/2 = 3
    @test length(dualmesh.dualedgedicts.auxiliary_onprimalface_dualedgedict) == 3*length(dualmesh.dualnodedicts.boundary_dualnodedict)

    @test length(dualmesh.dualfacedicts.interior_dualfacedict) + length(dualmesh.dualfacedicts.boundary_dualfacedict)== length(primalmesh.edgedict)
    # each boundary primal face has 3 auxiliary dual faces
    @test length(dualmesh.dualfacedicts.auxiliary_dualfacedict) == 3*length(dualmesh.dualnodedicts.boundary_dualnodedict)

    @test length(dualmesh.dualvolumedict) == length(primalmesh.nodedict)

    # checking boundary dual edges
    boundary_dualedgedict = dualmesh.dualedgedicts.boundary_dualedgedict
    @test boundary_dualedgedict[[1, 17, 32]].dualnodes == [193, [1, 17, 32]]
    @test boundary_dualedgedict[[6, 14, 43]].dualnodes == [199, [6, 14, 43]]

end 
#########################################################################################
# the test 2D mesh file is "2D_testmesh.msh"
# note the below line will only work when `pkg test`` (or equivalent) is run due to the additional "/test" appended to the front of the file path when testing in this manner
testfile_2D = "/meshes/2D_testmesh.msh"

@testset "mesher2D_parse.jl" begin

    nodedict, facedict_2D, physicalnames_dict, all_entities_struct_2D = DecqedMesher.Mesher2D_Parse.parsefile_2D(testfile_2D)

    # checking high-level info
    @test length(nodedict) == 29
    @test length(facedict_2D) == 40
    @test length(physicalnames_dict) == 2 # two physical names: id 1 is "boundary", 2 is "bulk", checked in next testset
    @test length(all_entities_struct_2D.point_entities_dict) == 4
    @test length(all_entities_struct_2D.curve_entities_dict) == 4
    @test length(all_entities_struct_2D.surface_entities_dict) == 1

end 

@testset "mesher2D_primalmesh.jl" begin

    primalmesh_2D, physicalnames_dict, all_entities_struct = DecqedMesher.Mesher2D_Primalmesh.complete_primalmesh_2D(testfile_2D)  

    # checking primalmesh_2D
    # checking primal node whose id is 4
    testnode = primalmesh_2D.nodedict[4]
    @test testnode.id == 4
    @test testnode.coords == [1, 1, 0]
    @test testnode.root_entitydim == 0
    @test testnode.root_entityid == 4
    # the following entity info is correct: curve tags: 2, 3; surface tags: 1
    @test testnode.entities_dict == Dict{Int64, Vector}(1 => Any[2, 3], 2 => Any[1])

    # checking physicalnames_dict
    @test physicalnames_dict[1].name == "boundary"
    @test physicalnames_dict[2].name == "bulk"

    # checking all_entities_struct
    # checking curve entity whose id is 2
    @test all_entities_struct.curve_entities_dict[2].curve_tag == 2
    @test all_entities_struct.curve_entities_dict[2].physicaltags == [1]
    @test all_entities_struct.curve_entities_dict[2].boundingpoints == [2, 4]

    println(primalmesh_2D.edgedict)

end 