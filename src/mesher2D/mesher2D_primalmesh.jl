module  Mesher2D_Primalmesh
export complete_primalmesh_2D

using ..Mesher3D_Primalmesh: getedgelen
# not included: getfacearea, gettetvol, complete_update_tet, edge2entities_map, complete_primalmesh

using ..Mesher2D_Types
using ..Mesher2D_Parse


using StaticArrays
using LinearAlgebra
using Combinatorics


"""
    getfacearea_2D(nodedict::Dict{Int, Nodestruct}, face::Facestruct_2D)

Return the area of face. The same as getfacearea() but uses Facestruct_2D instead of Facestruct, and hence 
uses the "nodes" field rather than "id".
"""
function getfacearea_2D(nodedict::Dict{Int, Nodestruct}, face_2D::Facestruct_2D)::Float64

    # get coords of nodes, using face.nodes instead of face.id in 3D
    node1coords = nodedict[face_2D.nodes[1]].coords
    node2coords = nodedict[face_2D.nodes[2]].coords
    node3coords = nodedict[face_2D.nodes[3]].coords

    # calculate area using cross product
    vec1 = node2coords - node1coords
    vec2 = node3coords - node1coords
    area = 1/2 * norm(cross(vec1, vec2))
    return area

end


"""
    complete_update_face(nodedict::Dict{Int, Nodestruct}, 
                              edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                              face_2D:: Facestruct_2D)

Updates the missing fields of face (its edges and area) and updates the associated structs
in the appropriate primal mesh dictionaries. This is the analogue of
complete_update_tet in 3D.
"""
function complete_update_face(nodedict::Dict{Int, Nodestruct}, 
                              edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                              facedict_2D:: Dict{Int, Facestruct_2D},
                              face_2D:: Facestruct_2D)

    # get nodeids of face
    nodeids = face_2D.nodes

    # instantiate empty Vector for tet to gather all edgeid info
    edgeid_face_vec = Vector{}()

    # get the 3 edgeids
    edgeid_face_vec = sort!.(collect(combinations(nodeids, 2)))

    # update info for each edge
    for edgeid in edgeid_face_vec
        
        # make Edgestruct & get length, then append to edgedict
        edge = Edgestruct()
        edge.id = edgeid
        edge.length = getedgelen(nodedict, edge)
        edgedict[edgeid] = edge

    end

    # update info for each face, then append to facedict_2D 
    face_2D.edges = edgeid_face_vec
    face_2D.area = getfacearea_2D(nodedict, face_2D)
    facedict_2D[face_2D.id] = face_2D

end


"""
    edge2entities_map_2D(nodedict::Dict{Int, Nodestruct}, edgedict::Dict{SVector{2, Int}, Edgestruct})

Adding information about which mesh entities each edge belongs to.
Same as edge2entities_map, except simply does not include a section for volume entities.
"""
function edge2entities_map_2D(nodedict::Dict{Int, Nodestruct}, edgedict::Dict{SVector{2, Int}, Edgestruct})

    for ekey in keys(edgedict)
        
        n1 = ekey[1]
        n2 = ekey[2]

        # instantiate empty dict to populate with entities for the edge
        entities_dict = Dict{Int,Vector{}}()
        
        if (nodedict[n1].entities_dict[1]!=[0])&&(nodedict[n2].entities_dict[1]!=[0])
            # Note: an edge can only lie on either 1 or 0 physical curves, hence findfirst
            # determines if the edge's two nodes are part of the same physical curve without loss of generality
            # if such a curve exists, returns the index of that curve in the vector of curvetags, entities_dict[1]
            sharedcurve_ind = findfirst(in(nodedict[n1].entities_dict[1]), nodedict[n2].entities_dict[1])
            if !isnothing(sharedcurve_ind) # if n1 and n2 both lie on the same curve
                # nodedict[n2].entities_dict[1] gives the array of curvetags
                entities_dict[1] = [nodedict[n2].entities_dict[1][sharedcurve_ind]]   
            else
                entities_dict[1] = [0]           
            end
        else 
            entities_dict[1] = [0]           
        end

        if (nodedict[n1].entities_dict[2]!=[0])&&(nodedict[n2].entities_dict[2]!=[0])
            # Note: if an edge lies on a curve, that edge can belong to multiple neighboring surfaces, hence findall
            sharedsurface_ind = findall(in(nodedict[n1].entities_dict[2]), nodedict[n2].entities_dict[2])
            if !isnothing(sharedsurface_ind) # if n1 and n2 lie on the same surface
                entities_dict[2] = nodedict[n2].entities_dict[2][sharedsurface_ind]
            else
                entities_dict[2] = [0]
            end
        else
            entities_dict[2] = [0]
        end

        edgedict[ekey].entities_dict = entities_dict
    
    end

end


"""
    complete_primalmesh_2D(file::String)

Returns the 4 completed primal mesh dictionaries.
Same as complete_primalmesh, except the dict for the highest-dimensional
obect is facedict_2D rather than tetdict.
"""
function complete_primalmesh_2D(file::String)
    
    # reads in the raw info from Gmsh
    nodedict, facedict_2D, physicalnames_dict, all_entities_struct = parsefile_2D(file)

    # instantiate empty dicts to store mesh dicts
    edgedict = Dict{SVector{2, Int}, Edgestruct}()
    
    # complete information for each face
    for face_2D_pair in facedict_2D
        complete_update_face(nodedict, edgedict, facedict_2D, face_2D_pair.second)
    end

    # complete entity info for each edge
    edge2entities_map_2D(nodedict, edgedict)

    # create completed primal mesh
    primalmesh_2D = Primalmeshstruct_2D()
    primalmesh_2D.nodedict = nodedict
    primalmesh_2D.edgedict = edgedict
    primalmesh_2D.facedict_2D = facedict_2D

    return primalmesh_2D, physicalnames_dict, all_entities_struct

end

end