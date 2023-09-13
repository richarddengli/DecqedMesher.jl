# This file implements the functionality to create the complete primal mesh.

module Mesher3D_Primalmesh
export getedgelen, getfacearea, gettetvol, complete_update_tet, edge2entities_map, complete_primalmesh

using ..Mesher3D_Types
using ..Mesher3D_Parse

#import FromFile: @from
# @from "mesher3D_types.jl" using Mesher3D_Types
# @from "mesher3D_parse.jl" using Mesher3D_Parse: parsefile

using StaticArrays
using LinearAlgebra
using Combinatorics


"""
    getedgelen(nodedict::Dict{Int, Nodestruct},  edge::Edgestruct)

Return the length of edge.
"""
function getedgelen(nodedict::Dict{Int, Nodestruct}, edge::Edgestruct)::Float64
    
    # get coords of nodes
    node1coords = nodedict[edge.id[1]].coords
    node2coords = nodedict[edge.id[2]].coords

    # calculate length
    vec = node1coords - node2coords
    length = norm(vec)
    return length

end


"""
    getfacearea(nodedict::Dict{Int, Nodestruct}, face::Facestruct)

Return the area of face.
"""
function getfacearea(nodedict::Dict{Int, Nodestruct}, face::Facestruct)::Float64

    # get coords of nodes
    node1coords = nodedict[face.id[1]].coords
    node2coords = nodedict[face.id[2]].coords
    node3coords = nodedict[face.id[3]].coords

    # calculate area using cross product
    vec1 = node2coords - node1coords
    vec2 = node3coords - node1coords
    area = 1/2 * norm(cross(vec1, vec2))
    return area

end


"""
    gettetvol(nodedict::Dict{Int, Nodestruct}, tet::Tetstruct)

Return the volume of tet.

Uses the cross-product formula.
"""
function gettetvol(nodedict::Dict{Int, Nodestruct}, tet::Tetstruct)::Float64

    # get nodeids belonging to tet
    nodeids = tet.nodes

    # get coords of nodes
    node1_coords = nodedict[nodeids[1]].coords
    node2_coords = nodedict[nodeids[2]].coords
    node3_coords = nodedict[nodeids[3]].coords
    node4_coords = nodedict[nodeids[4]].coords

    # calculate area using cross product
    a = node2_coords - node1_coords
    b = node3_coords - node1_coords
    c = node4_coords - node1_coords
    volume = 1/6 * abs(dot(cross(a, b), c))
    return volume

end


"""
    complete_update_tet(nodedict::Dict{Int, Nodestruct}, 
                        edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                        facedict::Dict{SVector{3, Int}, Facestruct}, 
                        tet::Tetstruct)

Updates the missing fields of tet and updates the associated structs
in the appropriate primal mesh dictionaries.
"""
function complete_update_tet(nodedict::Dict{Int, Nodestruct}, 
                             edgedict::Dict{SVector{2, Int}, Edgestruct}, 
                             facedict::Dict{SVector{3, Int}, Facestruct}, 
                             tet::Tetstruct)

    # get nodeids of tet
    nodeids = tet.nodes

    # instantiate empty Vectors for tet to gather all edgeid and faceid info
    edgeid_tet_vec = Vector{}()
    faceid_tet_vec = Vector{}()

    # get the 4 faceids
    faceid_tet_vec = sort!.(collect(combinations(nodeids, 3)))

    # update info for each face of the tet
    for faceid in faceid_tet_vec
        
        # get the 3 edgeids
        edgeids = sort!.(collect(combinations(faceid, 2)))

        # update info for each edge of that face
        for edgeid in edgeids
            
            # make Edgestruct & get length, then append to edgedict
            edge = Edgestruct()
            edge.id = edgeid
            edge.length = getedgelen(nodedict, edge)
            edgedict[edgeid] = edge

            # append edgeid to tet, if not already in 
            # (edges are shared between faces, so only keep the unique ones)
            if ~(edgeid in edgeid_tet_vec)
                push!(edgeid_tet_vec, edgeid)
            end

        end

        # make Facestruct & get area, then append to facedict
        face = Facestruct()
        face.id = faceid
        face.edges = edgeids
        face.area = getfacearea(nodedict, face)
        facedict[faceid] = face
        
    end
    
    # update info for tet
    tet.edges = edgeid_tet_vec
    tet.faces = faceid_tet_vec
    tet.volume = gettetvol(nodedict, tet)

end


"""
    edge2entities_map(nodedict::Dict{Int, Nodestruct}, edgedict::Dict{SVector{2, Int}, Edgestruct})

Adding information about which mesh entities each edge belongs to.
"""
function edge2entities_map(nodedict::Dict{Int, Nodestruct}, edgedict::Dict{SVector{2, Int}, Edgestruct})

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

        if (nodedict[n1].entities_dict[3]!=[0])&&(nodedict[n2].entities_dict[3]!=[0])
            # Note: if an edge lies on a curve or a surface, that edge can belong to multiple neighboring volumes, hence findall
            sharedvolume_ind = findall(in(nodedict[n1].entities_dict[3]), nodedict[n2].entities_dict[3])
            if !isnothing(sharedvolume_ind) # if n1 and n2 lie in the same volume
                entities_dict[3] = nodedict[n2].entities_dict[3][sharedvolume_ind]
            else
                entities_dict[3] = [0]
            end
        else
            entities_dict[3] = [0]
        end

        edgedict[ekey].entities_dict = entities_dict
    
    end

end


"""
    complete_primalmesh(file::String)

Returns the 4 completed primal mesh dictionaries.
"""
function complete_primalmesh(file::String)

    # reads in the raw info from Gmsh
    nodedict, tetdict, physicalnames_dict, all_entities_struct = parsefile(file)

    # instantiate empty dicts to store mesh dicts
    edgedict = Dict{SVector{2, Int}, Edgestruct}()
    facedict = Dict{SVector{3, Int}, Facestruct}()
    
    # complete information for each tet
    for tetpair in tetdict
        complete_update_tet(nodedict, edgedict, facedict, tetpair.second)
    end

    # complete entity info for each edge
    edge2entities_map(nodedict, edgedict)

    # create completed primal mesh
    primalmesh = Primalmeshstruct()
    primalmesh.nodedict = nodedict
    primalmesh.edgedict = edgedict
    primalmesh.facedict = facedict
    primalmesh.tetdict  = tetdict

    return primalmesh, physicalnames_dict, all_entities_struct

end

end

# test
# @time primalmesh = Mesher3D_Primalmesh.complete_primalmesh(raw"/meshes/transfinite_test.msh")
