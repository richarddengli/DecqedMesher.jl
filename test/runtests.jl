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

    # println(primalmesh.tetdict[114])

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

    # check raw volumes of all dual volumes add up to the mesh volume (1*1*1=1). This is quite remarkable, meaning the orientation of certain objects are accounted for in Hirani's method.
    raw_volume_sum = 0
    for dualvolumepair in dualmesh.dualvolumedict
        raw_volume_sum += dualvolumepair.second.raw_volume
    end 
    @test isapprox(raw_volume_sum, 1, rtol=0.00000001)

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

    # println(primalmesh_2D.edgedict)

end 

@testset "mesher2D_dualmesh.jl" begin

    primalmesh_2D, physicalnames_dict, all_entities_struct = DecqedMesher.Mesher2D_Primalmesh.complete_primalmesh_2D(testfile_2D)  

    # interior face
    testface_2D_interior = primalmesh_2D.facedict_2D[33]
    @test DecqedMesher.Mesher2D_Dualmesh.get_circumcenter_face_2D(testface_2D_interior, primalmesh_2D.nodedict) == [0.5684523809523139, 0.6398809523809739, 0.0]

    # boundary face
    testface_2D_boundary = primalmesh_2D.facedict_2D[25]
    @test DecqedMesher.Mesher2D_Dualmesh.get_circumcenter_face_2D(testface_2D_boundary, primalmesh_2D.nodedict) == [0.6250000000012046, 0.8898809523797038, 0.0]

    # interior dualnodes
    interior_dualnodedict_2D = DecqedMesher.Mesher2D_Dualmesh.create_interior_dualnodedict_2D(primalmesh_2D.nodedict, primalmesh_2D.facedict_2D)
    @test length(interior_dualnodedict_2D) ==  length(primalmesh_2D.facedict_2D)

    # boundary dualnodes
    boundary_dualnodedict_2D = DecqedMesher.Mesher2D_Dualmesh.create_boundary_dualnodedict_2D(primalmesh_2D.nodedict, primalmesh_2D.edgedict, primalmesh_2D.facedict_2D)
    @test length(boundary_dualnodedict_2D) == 16 # by inspection, each side of the mesh has 4 boundary edges

    # all dualnodes
    dualnodedicts_2D = DecqedMesher.Mesher2D_Dualmesh.create_dualnodedicts_2D(primalmesh_2D.nodedict, primalmesh_2D.edgedict, primalmesh_2D.facedict_2D)
    @test length(dualnodedicts_2D.interior_dualnodedict_2D) == length(interior_dualnodedict_2D)
    @test length(dualnodedicts_2D.boundary_dualnodedict_2D) == length(boundary_dualnodedict_2D)

    # interior dualedges
    interior_dualedgedict_2D = DecqedMesher.Mesher2D_Dualmesh.create_interior_dualedgedict_2D(primalmesh_2D.edgedict, primalmesh_2D.facedict_2D, interior_dualnodedict_2D, boundary_dualnodedict_2D)
    @test length(interior_dualedgedict_2D) + length(boundary_dualnodedict_2D) == length(primalmesh_2D.edgedict)

    # boundary dualedges
    boundary_dualedgedict_2D = DecqedMesher.Mesher2D_Dualmesh.create_boundary_dualedgedict_2D(interior_dualnodedict_2D, boundary_dualnodedict_2D)
    @test length(boundary_dualedgedict_2D) == 16

    # auxiliary (on primal edge) dualedges
    auxiliary_onprimaledge_dualedgedict_2D = DecqedMesher.Mesher2D_Dualmesh.create_auxiliary_onprimaledge_dualedgedict_2D(primalmesh_2D.nodedict, boundary_dualnodedict_2D)
    @test length(auxiliary_onprimaledge_dualedgedict_2D) == 16*2 # each boundary primal edge has 2 auxiliary dual edges

    # all dualedges
    dualedgedicts_2D = DecqedMesher.Mesher2D_Dualmesh.create_dualedgedicts_2D(primalmesh_2D.nodedict, primalmesh_2D.edgedict, primalmesh_2D.facedict_2D, interior_dualnodedict_2D, boundary_dualnodedict_2D)
    @test length(dualedgedicts_2D.interior_dualedgedict_2D) == length(interior_dualedgedict_2D)
    @test length(dualedgedicts_2D.boundary_dualedgedict_2D) == length(boundary_dualedgedict_2D)
    @test length(dualedgedicts_2D.auxiliary_onprimaledge_dualedgedict_2D) == length(auxiliary_onprimaledge_dualedgedict_2D)

    # get_dualarea_rawvalue_2D()
    # check raw area of all dual faces add up to the mesh area (1*1=1)
    raw_area_sum = 0
    for nodepair in primalmesh_2D.nodedict
        area = DecqedMesher.Mesher2D_Dualmesh.get_dualarea_rawvalue_2D(nodepair.second, primalmesh_2D.nodedict, primalmesh_2D.edgedict, primalmesh_2D.facedict_2D)
        raw_area_sum += area
    end 
    @test isapprox(raw_area_sum, 1, rtol=0.00000001)  




    # visual checks
    using Plots

    # dual node plots
    coords_list = []
    for interior_dualnode_2D_pair in interior_dualnodedict_2D
        coords = interior_dualnode_2D_pair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter(x_coords, y_coords, legend=false)
    savefig("interior dual nodes")

    coords_list = []
    for boundary_dualnode_2D_pair in boundary_dualnodedict_2D
        coords = boundary_dualnode_2D_pair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter(x_coords, y_coords, legend=false)
    savefig("boundary dual nodes")

    # interior dual edge plots with interior dual nodes
    plot()

    coords_list = []
    for interior_dualnode_2D_pair in interior_dualnodedict_2D
        coords = interior_dualnode_2D_pair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter(x_coords, y_coords, legend=false)

    for interior_dualedge_2D_pair in interior_dualedgedict_2D
        dualnode_ids = interior_dualedge_2D_pair.second.dualnodes
        coord1 = interior_dualnodedict_2D[dualnode_ids[1]].coords
        coord2 = interior_dualnodedict_2D[dualnode_ids[2]].coords
        plot!([coord1[1], coord2[1]], [coord1[2], coord2[2]], legend=false, color="purple")
    end 
    savefig("interior dual edges")

    # boundary dual edge plots with boundary dual nodes
    plot()

    coords_list = []
    for boundary_dualnode_2D_pair in boundary_dualnodedict_2D
        coords = boundary_dualnode_2D_pair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter(x_coords, y_coords, legend=false)

    for boundary_dualedge_2D_pair in boundary_dualedgedict_2D
        dualnode_ids = boundary_dualedge_2D_pair.second.dualnodes
        coord1 = interior_dualnodedict_2D[dualnode_ids[1]].coords
        coord2 = boundary_dualnodedict_2D[dualnode_ids[2]].coords
        plot!([coord1[1], coord2[1]], [coord1[2], coord2[2]], legend=false, color="purple")
    end 
    savefig("boundary dual edges")

    # auxiliary (on primal edge) dual edges with boundary dual nodes and primal nodes
    plot()

    coords_list = []
    for boundary_dualnode_2D_pair in boundary_dualnodedict_2D
        coords = boundary_dualnode_2D_pair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter(x_coords, y_coords, legend=false)

    coords_list = []
    for nodepair in primalmesh_2D.nodedict
        coords = nodepair.second.coords
        push!(coords_list, coords)
    end
    x_coords = [point[1] for point in coords_list]
    y_coords = [point[2] for point in coords_list]
    scatter!(x_coords, y_coords, legend=false)

    for auxiliary_onprimaledge_dualedge_2D_pair in auxiliary_onprimaledge_dualedgedict_2D
        dualnode_ids = auxiliary_onprimaledge_dualedge_2D_pair.second.id
        coord1 = boundary_dualnodedict_2D[dualnode_ids[1]].coords
        coord2 = primalmesh_2D.nodedict[dualnode_ids[2]].coords
        plot!([coord1[1], coord2[1]], [coord1[2], coord2[2]], legend=false, color="purple")
    end 
    savefig("auxiliary (on primal edge) dual edges")
    
end 