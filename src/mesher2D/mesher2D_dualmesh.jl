module  Mesher2D_Dualmesh

using ..Mesher3D_Dualmesh: get_midpoint_edge, get_area_triangle, get_edgesfornode
# functionality that are not imported from mesher3D but have a mesher2D analogue are listed in the following table: 
# ____________________________________________
# mesher3D implementation | mesher2D analogue
# ____________________________________________
# get_circumcenter_tet, get_circumcenter_face  | get_circumcenter_face_2D
# create_interior_dualnodedict | create_interior_dualnodedict_2D
# get_tetsforface | get_faces2D_foredge
# get_circumcenter_face | get_circumcenter_face_2D 
# create_dualnodedicts | create_dualnodedicts_2D
# create_interior_dualedgedict | create_interior_dualedgedict_2D
# create_boundary_dualedgedict | create_boundary_dualedgedict_2D
# create_auxiliary_onprimaledge_dualedgedict, create_auxiliary_onprimalface_dualedgedict | create_auxiliary_onprimaledge_dualedgedict_2D
# create_dualedgedicts | create_dualedgedicts_2D
# get_dualarea_rawvalue, get_dualvolume_rawvalue | get_dualarea_rawvalue_2D

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
An edge is on the boundary iff it belongs to only 1 face.
"""
function create_boundary_dualnodedict_2D(nodedict::Dict{Int, Nodestruct},
                                         edgedict::Dict{SVector{2, Int}, Edgestruct},
                                         facedict_2D::Dict{Int, Facestruct_2D})::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}

    boundary_dualnodedict_2D = Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}()

    for edgepair in edgedict

        edgeid = edgepair.first
        edge = edgepair.second

        # get face_2Ds sharing edge
        faceids_2D = get_faces2D_foredge(edge, facedict_2D)

        # if only one face shares edge, then edge on boundary
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



"""
    create_dualnodedicts_2D(nodedict::Dict{Int, Nodestruct}, 
                                 edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                                 facedict_2D::Dict{Int, Facestruct_2D})

Create dualnodedicts.
"""
function create_dualnodedicts_2D(nodedict::Dict{Int, Nodestruct}, 
                                 edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                                 facedict_2D::Dict{Int, Facestruct_2D})::Dualnodedicts_struct_2D

    dualnodedicts_2D = Dualnodedicts_struct_2D()

    dualnodedicts_2D.interior_dualnodedict_2D = create_interior_dualnodedict_2D(nodedict, facedict_2D)
    dualnodedicts_2D.boundary_dualnodedict_2D = create_boundary_dualnodedict_2D(nodedict, edgedict, facedict_2D)

    return dualnodedicts_2D

end
############################ END DUAL NODES ############################
############################ START DUAL EDGES ############################
"""
    create_interior_dualedgedict_2D(edgedict::Dict{SVector{2, Int}, Edgestruct},
                                    facedict_2D::Dict{Int, Facestruct_2D}, 
                                    interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D},
                                    boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}

Create dictionary of interior dual edges.

The list of interior primal edges is obtained by the set difference between edgedict and boundary_dualnodedict_2D.
"""
function  create_interior_dualedgedict_2D(edgedict::Dict{SVector{2, Int}, Edgestruct},
                                          facedict_2D::Dict{Int, Facestruct_2D}, 
                                          interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D},
                                          boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})::Dict{SVector{2, Int}, Interior_dualedgestruct_2D}

    interior_dualedgedict_2D = Dict{SVector{2, Int}, Interior_dualedgestruct_2D}()

    # get list of interior primal edges 
    interior_primaledgeids = setdiff(keys(edgedict), keys(boundary_dualnodedict_2D))
    
    # make each interior dual edge
    for interior_primaledgeid in interior_primaledgeids

        interior_dualedge_2D = Interior_dualedgestruct_2D()
        interior_dualedge_2D.id = interior_primaledgeid
        interior_dualedge_2D.dualnodes = get_faces2D_foredge(edgedict[interior_primaledgeid], facedict_2D) # [interior dual node id 1, interior dual node id 2], in ascending order

        vec = interior_dualnodedict_2D[interior_dualedge_2D.dualnodes[1]].coords - interior_dualnodedict_2D[interior_dualedge_2D.dualnodes[2]].coords
        interior_dualedge_2D.length = norm(vec)

        # insert into dict
        interior_dualedgedict_2D[interior_dualedge_2D.id] = interior_dualedge_2D

    end

    return interior_dualedgedict_2D

end


"""
    function create_boundary_dualedgedict_2D(interior_dualnodedict_2D::Dict{SVector{2, Int}, Interior_dualedgestruct_2D}, 
                                             boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})

Create dictionary of boundary dual edges. 

The list of boundary primal edge ids are contained in boundary_dualnodedict_2D.
"""
function create_boundary_dualedgedict_2D(interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D}, 
                                         boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})::Dict{SVector{2, Int}, Boundary_dualedgestruct_2D}

    boundary_dualedgedict_2D = Dict{SVector{2, Int}, Boundary_dualedgestruct_2D}()                                  

    # make each boundary dual edge
    for boundary_dualnodepair_2D in boundary_dualnodedict_2D

        boundary_dualnodeid_2D = boundary_dualnodepair_2D.first
        boundary_dualnode_2D = boundary_dualnodepair_2D.second

        boundary_dualedge_2D = Boundary_dualedgestruct_2D()
        boundary_dualedge_2D.id = boundary_dualnodeid_2D
        boundary_dualedge_2D.dualnodes = [boundary_dualnode_2D.face, boundary_dualnodeid_2D]  # [interior dual node id, boundary dual node id] 
        
        vec = interior_dualnodedict_2D[boundary_dualedge_2D.dualnodes[1]].coords - boundary_dualnodedict_2D[boundary_dualedge_2D.dualnodes[2]].coords
        boundary_dualedge_2D.length = norm(vec)

        # insert into dict
        boundary_dualedgedict_2D[boundary_dualedge_2D.id] = boundary_dualedge_2D
         
    end

    return boundary_dualedgedict_2D

end


"""
    create_auxiliary_onprimaledge_dualedgedict_2D(nodedict::Dict{Int, Nodestruct},
                                                  boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})

Create dictionary of auxiliary dual edges lying on part of a boundary primal edge.

Each such dual edge corresponds to a tuple (boundary primal edge, primal node part of that boundary primal edge).
Boundary primal edge ids are already listed in boundary_dualnodedict_2D.
"""
function create_auxiliary_onprimaledge_dualedgedict_2D(nodedict::Dict{Int, Nodestruct},
                                                       boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})::Dict{SVector{2, Any}, Auxiliary_onprimaledge_dualedgestruct_2D}

    auxiliary_onprimaledge_dualedgedict_2D = Dict{SVector{2, Any}, Auxiliary_onprimaledge_dualedgestruct_2D}()           
    
    # make auxiliary_onprimaledge_dualedgedict, by looping over each tuple (boundary primal edge, primal node part of that boundary primal edge), 
    # & insert into dict
    for boundary_primaledgeid in keys(boundary_dualnodedict_2D)

        for boundary_primalnodeid in boundary_primaledgeid

            auxiliary_onprimaledge_dualedge_2D = Auxiliary_onprimaledge_dualedgestruct_2D()
            auxiliary_onprimaledge_dualedge_2D.id = [boundary_primaledgeid, boundary_primalnodeid] 
            
            vec = boundary_dualnodedict_2D[auxiliary_onprimaledge_dualedge_2D.id[1]].coords - nodedict[auxiliary_onprimaledge_dualedge_2D.id[2]].coords
            auxiliary_onprimaledge_dualedge_2D.length = norm(vec)

            auxiliary_onprimaledge_dualedgedict_2D[auxiliary_onprimaledge_dualedge_2D.id] = auxiliary_onprimaledge_dualedge_2D

        end

    end

    return auxiliary_onprimaledge_dualedgedict_2D

end


"""
    create_dualedgedicts_2D(nodedict::Dict{Int, Nodestruct}, 
                            edgedict::Dict{SVector{2, Int}, Edgestruct},
                            facedict_2D::Dict{Int, Facestruct_2D}, 
                            interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D}, 
                            boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})


Create dualedgedicts.
"""
function create_dualedgedicts_2D(nodedict::Dict{Int, Nodestruct}, 
                                 edgedict::Dict{SVector{2, Int}, Edgestruct},
                                 facedict_2D::Dict{Int, Facestruct_2D}, 
                                 interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D}, 
                                 boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D})::Dualedgedicts_struct_2D
    
    dualedgedicts_2D = Dualedgedicts_struct_2D()
    dualedgedicts_2D.interior_dualedgedict_2D = create_interior_dualedgedict_2D(edgedict, facedict_2D, interior_dualnodedict_2D, boundary_dualnodedict_2D)
    dualedgedicts_2D.boundary_dualedgedict_2D = create_boundary_dualedgedict_2D(interior_dualnodedict_2D, boundary_dualnodedict_2D)
    dualedgedicts_2D.auxiliary_onprimaledge_dualedgedict_2D = create_auxiliary_onprimaledge_dualedgedict_2D(nodedict, boundary_dualnodedict_2D)

    return dualedgedicts_2D

end
############################ END DUAL EDGES ############################

############################ START DUAL FACES ############################
"""
    get_dualarea_rawvalue_2D(node::Nodestruct,
                             nodedict::Dict{Int, Nodestruct},
                             edgedict::Dict{SVector{2, Int}, Edgestruct},
                             facedict_2D::Dict{Int, Facestruct_2D})

Determine the raw value of the dual area corresponding to a primal node using Hirani's method.

Hirani, A. N., Kalyanaraman, K., & VanderZee, E. B. (2013). Delaunay hodge star. Computer-Aided Design, 45(2), 540-544.
"""
function get_dualarea_rawvalue_2D(node::Nodestruct,
                                  nodedict::Dict{Int, Nodestruct},
                                  edgedict::Dict{SVector{2, Int}, Edgestruct},
                                  facedict_2D::Dict{Int, Facestruct_2D})::Float64

    dualarea_value = 0

    nodeid = node.id

    # get list of edges containing node
    edgelist = []
    for edgepair in edgedict
        edgeid = edgepair.first
        if nodeid in edgeid
            push!(edgelist, edgeid)
        end
    end

    # for each edge in above list, 
    # get the list of faces containing that edge
    for edgeid in edgelist

        edge = edgedict[edgeid]

        faceids_list_2D = []
        for facepair_2D in facedict_2D
            facenodes = facepair_2D.second.nodes
            if issubset(edgeid, facenodes)
                push!(faceids_list_2D, facepair_2D.first)
            end
        end


        for faceid_2D in faceids_list_2D

            face_2D = facedict_2D[faceid_2D]

            # calculate multiplier

            # calculate lambda1 (omitted, since it is always 1)
            mp = get_midpoint_edge(edge, nodedict) # mp is used later

            lambda1 = 1

            # calculate lambda2 
            vp2 = setdiff(face_2D.nodes,  edgeid)[1]

            vp2_coords = nodedict[vp2].coords

            vector1 = vp2_coords - nodedict[edgeid[1]].coords
            vector2 = vp2_coords - nodedict[edgeid[2]].coords
            face_normal = cross(vector1, vector2)
            vector3 = nodedict[edgeid[2]].coords - nodedict[edgeid[1]].coords
            halfspace_plane_normal = cross(face_normal, vector3)

            a = halfspace_plane_normal[1]
            b = halfspace_plane_normal[2]
            c = halfspace_plane_normal[3]
            x0 = nodedict[edgeid[1]].coords[1]
            y0 = nodedict[edgeid[1]].coords[2]
            z0 = nodedict[edgeid[1]].coords[3]
            face_circumcenter = get_circumcenter_face_2D(face_2D, nodedict)

            sign_vp2 = sign(a*(vp2_coords[1] - x0) + b*(vp2_coords[2] - y0) + c*(vp2_coords[3] - z0))
            sign_face_circumcenter = sign(a*(face_circumcenter[1] - x0) + b*(face_circumcenter[2] - y0) + c*(face_circumcenter[3] - z0))

            lambda2 = -1
            if sign_vp2 == sign_face_circumcenter
                lambda2 = 1
            end

            # calculate overall multiplier
            multiplier = lambda1 * lambda2

            # add to dual volume
            triangle_area = get_area_triangle(node.coords, mp, face_circumcenter)
            dualarea_value += multiplier * triangle_area

        end

    end

    return dualarea_value

end


function get_dualface_2D(node::Nodestruct, 
                         nodedict::Dict{Int, Nodestruct},
                         edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                         facedict_2D::Dict{Int, Facestruct_2D}, 
                         interior_dualedgedict_2D::Dict{SVector{2, Int}, Interior_dualedgestruct_2D},  
                         boundary_dualedgedict_2D::Dict{SVector{2, Int}, Boundary_dualedgestruct_2D},
                         auxiliary_onprimaledge_dualedgedict_2D::Dict{SVector{2, Any}, Auxiliary_onprimaledge_dualedgestruct_2D})::Dualfacestruct_2D

    dualface_2D = Dualfacestruct_2D()

    dualface_2D.id = node.id

    dualface_2D.raw_area = get_dualarea_rawvalue_2D(node, nodedict, edgedict, facedict_2D)

    dualface_2D.interior_dualedges = Vector{SVector{2, Int}}()
    dualface_2D.boundary_dualedges = Vector{SVector{2, Int}}()
    dualface_2D.auxiliary_onprimaledge_dualedges = Vector{SVector{2, Any}}()

    # get primal edges containing node
    parent_edgeids = get_edgesfornode(node, edgedict)

    # see which dict each edge above belongs to
    for parent_edgeid in parent_edgeids

        if parent_edgeid in keys(boundary_dualedgedict_2D)
            push!(dualface_2D.boundary_dualedges, parent_edgeid)
        else
            push!(dualface_2D.interior_dualedges, parent_edgeid)
        end

    end
    sort!(dualface_2D.boundary_dualedges)
    sort!(dualface_2D.interior_dualedges)

    # append auxiliary (on primal edge) dual edge, if its id, [boundary primal edge id, primal node part of that primal edge], contains node
    for auxiliary_onprimaledge_dualedge_2D_pair in auxiliary_onprimaledge_dualedgedict_2D

        auxiliary_onprimaledge_dualedge_2D_id = auxiliary_onprimaledge_dualedge_2D_pair.first
        nodeid = node.id

        if nodeid == auxiliary_onprimaledge_dualedge_2D_id[2]
            push!(dualface_2D.auxiliary_onprimaledge_dualedges, auxiliary_onprimaledge_dualedge_2D_id)
        end 

    end
    sort!(dualface_2D.auxiliary_onprimaledge_dualedges)

    # complete rest of info for dual face

    # get all interior dual nodes, by looping over each of the dual face's
    # interior dual edges
    # and retrieving the interior dual nodes
    # use union of sets to only include unique elements 
    all_interior_dualnodes = Set([])

    for interior_dualedge_id in dualface_2D.interior_dualedges   
        union!(all_interior_dualnodes, Set(interior_dualedgedict_2D[interior_dualedge_id].dualnodes))
    end

    dualface_2D.interior_dualnodes = sort(collect(all_interior_dualnodes)) # convert back to vector
    


    # in 2D case, boundary_dualnodes is simply the same as boundary_dualedges
    dualface_2D.boundary_dualnodes = dualface_2D.boundary_dualedges
    # moreover, unlike 3D case, it is not necessary to loop over the auxiliary_onprimaledge_dualedges because all 
    # boundary dual nodes are already found above

    return dualface_2D

end
############################ END DUAL FACES ############################



end