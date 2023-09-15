module  Mesher2D_Dualmesh

using ..Mesher3D_Dualmesh: get_midpoint_edge
# functionality that are not imported from mesher3D are listed in the following table, with a description of its mesher2D analogue (if applicable): 

# mesher3D implementation | mesher2D analogue
# ____________________________________________
# get_circumcenter_tet    | -
# create_interior_dualnodedict | create_interior_dualnodedict_2D
# get_tetsforface | -
# get_circumcenter_face | get_circumcenter_face_2D 

using ..Mesher2D_Types
using ..Mesher2D_Parse
using ..Mesher2D_Primalmesh

using StaticArrays
using LinearAlgebra
using Combinatorics

############################ START DUAL NODES ############################
"""
    get_circumcenter_face_2D(face_2D::Facestruct_2D, 
                             nodedict::Dict{Int, Nodestruct})

Return the circumcenter of face_2D. 
Same as get_circumcenter_face, except uses facestruct_2D instead of facestruct.
"""
function get_circumcenter_face_2D(face_2D::Facestruct_2D, 
                                  nodedict::Dict{Int, Nodestruct})::SVector{3, Float64}
    
    # get nodeids of face
    nodeids = face_2D.nodes

    # get node coords
    a = nodedict[nodeids[1]].coords
    b = nodedict[nodeids[2]].coords
    c = nodedict[nodeids[3]].coords

    # get circumcenter
    circumcenter =  begin
                        a + 
                        ((norm(c-a)^2 * cross(cross(b-a, c-a), b-a)) 
                        + (norm(b-a))^2 * cross(cross(c-a, b-a), c-a)) /
                        (2 * norm(cross(b-a, c-a))^2)
                    end 
    
    return circumcenter 

end


"""
    create_interior_dualnodedict_2D(nodedict::Dict{Int, Nodestruct}, 
                                    facedict_2D::Dict{Int, Facestruct_2D})

Create the interior_dualnodedict_2D, given facedict_2D.
"""
function create_interior_dualnodedict_2D(nodedict::Dict{Int, Nodestruct}, 
                                         facedict_2D::Dict{Int, Facestruct_2D})::Dict{Int, Interior_dualnodestruct_2D}

    interior_dualnodedict_2D = Dict{Int, Interior_dualnodestruct_2D}()

    for facepair_2D in facedict_2D

        faceid_2D = facepair_2D.first
        face_2D = facepair_2D.second

        # make interior_dualnodestruct_2D & insert into dict
        interior_dualnode_2D = Interior_dualnodestruct_2D()
        interior_dualnode_2D.id = faceid_2D
        interior_dualnode_2D.coords = get_circumcenter_face_2D(face_2D, nodedict)
        
        interior_dualnodedict_2D[faceid_2D] = interior_dualnode_2D
    
    end

    return interior_dualnodedict_2D

end


"""
    get_tetsforface(face::Facestruct, 
                    tetdict::Dict{Int, Tetstruct})

Return the face_2D ids that edge belongs to.
- Length 1 vector if edge is on boundary
- length 2 if edge is in interior (asc order of nodeid)
"""
function get_faces2D_foredge(edge::Edgestruct, 
                             facedict_2D::Dict{Int, Facestruct_2D})::Vector{Int}

    # get set of nodes that make up edge
    edgeid = edge.id

    # find which tets contain this face
    parent_faceids_2D = []

    for facepair_2D in facedict_2D
        
        facenodes_2D = facepair_2D.second.nodes
        if issubset(edgeid, facenodes_2D)
            push!(parent_faceids_2D, facepair_2D.first)
        end
    
    end
    
    return sort(parent_faceids_2D)

end


"""
    create_boundary_dualnodedict_2D(nodedict::Dict{Int, Nodestruct},
                                    edgedict::Dict{SVector{3, Int}, Facestruct}, 
                                    facedict_2D::Dict{Int, Facestruct_2D})

Create the boundary_dualnodedict_2D, given edgedict.
A face is on the boundary iff it belongs to only 1 tet.
"""
function create_boundary_dualnodedict(nodedict::Dict{Int, Nodestruct},
                                      edgedict::Dict{SVector{2, Int}, Edgestruct},
                                      facedict_2D::Dict{Int, Facestruct_2D})::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}

    boundary_dualnodedict_2D = Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}()

    for edgepair in edgedict

        edgeid = edgepair.first
        edge = edgepair.second

        # get face_2Ds sharing edge
        faceids_2D = get_faces2D_foredge(edge, facedict_2D)

        # if only one face shares edge, then face on boundary
        if length(faceids_2D) == 1

            # make boundary dual node & insert into dict
            boundary_dualnode_2D = Boundary_dualnodestruct_2D()
            boundary_dualnode_2D.id = edgeid
            boundary_dualnode_2D.coords = get_midpoint_edge(edge, nodedict)
            boundary_dualnode_2D.face = faceids_2D[1]

            boundary_dualnodedict_2D[edgeid] = boundary_dualnode_2D
        
        end
    
    end

    return boundary_dualnodedict_2D

end
############################ END DUAL NODES ############################



end