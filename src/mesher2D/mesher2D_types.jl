module Mesher2D_Types
# the suffix "_2D" will be used to emphasize many declarations that are in direct correspondence with or analogous to, but not indentical to, their 3D counterparts
# comments above the type declarations describe how they are different 

import FromFile: @from

export Physicalname_struct, Point_entity_struct, Curve_entity_struct, Surface_entity_struct, All_entities_struct_2D
export Nodestruct, Edgestruct, Facestruct_2D, Primalmeshstruct_2D
export Interior_dualnodestruct_2D, Boundary_dualnodestruct_2D, Interior_dualedgestruct_2D, Boundary_dualedgestruct_2D, Auxiliary_onprimaledge_dualedgestruct_2D, Dualfacestruct_2D, Dualnodedicts_struct_2D, Dualedgedicts_struct_2D, Dualmeshstruct_2D

# Using static arrays may improve performance for certain purposes
using StaticArrays
########################################### Start material information ###########################################


# @from "../mesher3D/mesher3D_types.jl" import Mesher3D_Types: Physicalname_struct, Point_entity_struct, Curve_entity_struct, Surface_entity_struct 
@from "../mesher3D/mesher3D_types.jl" using Mesher3D_Types: Physicalname_struct, Point_entity_struct, Curve_entity_struct, Surface_entity_struct
# not included: Volume_entity_struct, All_entities_struct

# declare struct to contain all entities
# same as All_entities_struct but does not include a dict for volumes
mutable struct All_entities_struct_2D
    point_entities_dict::Dict{Int, Point_entity_struct}
    curve_entities_dict::Dict{Int, Curve_entity_struct}
    surface_entities_dict::Dict{Int, Surface_entity_struct}
    All_entities_struct_2D() = new()
end


########################################### End material information ###########################################
########################################### Start primal mesh ###########################################


@from "../mesher3D/mesher3D_types.jl" using Mesher3D_Types: Nodestruct, Edgestruct
# not included: Facestruct, Tetstruct, Primalmeshstruct

# note, Edgestruct supportvolume is really a support area in 2D 
# but we avoid declaration of a new struct given that the significance of the quantity is clear from context


# declare struct to contain face information
# note, we follow the convention of the 3D counterpart and use an Int to label the highest dimensional primal object (which is precisely a face in 2D)
# rather than using the 3 primal nodes for a face
mutable struct Facestruct_2D
    id::Int 
    nodes::SVector{3, Int} 
    edges::SVector{3, SVector{2, Int}} 
    area::Float64
    entityid:: Int
    Facestruct_2D() = new()
end


# declare struct to contain all primal mesh dicts
# same as Primalmeshstruct but does not include a dict for tets
# also note the convention of Facestruct_2D described previously
mutable struct Primalmeshstruct_2D
    nodedict::Dict{Int, Nodestruct}
    edgedict::Dict{SVector{2, Int}, Edgestruct}
    facedict_2D::Dict{Int, Facestruct_2D}
    Primalmeshstruct_2D() = new()
end


########################################### End primal mesh ###########################################
########################################### Start dual mesh ###########################################
# no imports are made from mesher3D_types

# note, we could have imported Interior_dualnodestruct given the id of type Int works for both primal face/tet ids, 
# but here we choose to declare new struct in order to emphasize the distinction between 2D and 3D dual objects

# declare struct to contain interior dual node information
# an interior dual node corresponds to the circumcenter of a primal face
mutable struct Interior_dualnodestruct_2D
    id::Int # primal face id
    coords::SVector{3, Float64} 
    Interior_dualnodestruct_2D() = new()
end


# declare struct to contain boundary dual node information
# a boundary dual node in 2D is the circumcenter of a boundary primal edge
# arising from the truncation of the dual mesh at the primal mesh boundary
# in 3D, a boundary dual node is the circumcenter of a boundary primal face because that is the boundary object of dimension (highest dimension - 1)
# thus in 2D, a boundary dual node is the circumcenter of a 2-1=1 dimensional boundary object, i.e. a boundary primal edge
# So Boundary_dualnodestruct_2D shares characteristics with both Boundary_dualnodestruct in 3D (it is the boundary object of dimension 
# equal to (highest dimension -1)) and also Auxiliary_dualnodestruct in 3D (it is circumcenter of a boundary primal edge)
mutable struct Boundary_dualnodestruct_2D
    id::SVector{2, Int} # boundary primal edge id
    coords::SVector{3, Float64}
    face::Int # primal face id, this info is contained here mainly so it can be used in Boundary_dualedgestruct_2D
    Boundary_dualnodestruct_2D() = new()
end


# declare struct to contain interior dual edge information
# an interior dual edge corresponds to an interior primal edge
# (i.e. a primal edge which is shared by 2 faces)
mutable struct Interior_dualedgestruct_2D
    id::SVector{2, Int} # interior primal edge id
    dualnodes::SVector{2, Int} # [interior dual node 2D id 1, interior dual node 2D id 2], in ascending order
    length::Float64
    Interior_dualedgestruct_2D() = new()
end 


# declare struct to contain boundary dual edge information
# a boundary dual edge corresponds to a boundary primal face
# (i.e. a primal face which is shared by only 1 face)
mutable struct Boundary_dualedgestruct_2D
    id::SVector{2, Int} # boundary primal edge id
    dualnodes::SVector{2, Any} # [interior dual node 2D id, boundary dual node 2D id] 
    length::Float64
    Boundary_dualedgestruct_2D() = new()
end


# an auxiliary dual edge lying on a boundary primary edge
# corresponds to a tuple (boundary primal edge, primal node part of that boundary primal edge)
mutable struct Auxiliary_onprimaledge_dualedgestruct_2D
    id::SVector{2, Any} # [boundary primal edge id, primal node part of that boundary primal edge id] , this is equivalent to its dualnodes [boundary dual node 2D id, primal node part of that boundary primal edge id]. Note a primal node that is part of a boundary primal edge is effectively also a dual node, hence we did not need to declare a struct for it. 
    length::Float64
    Auxiliary_onprimaledge_dualedgestruct_2D() = new()
end


# declare struct to contain dual volume information
# a dual face corresponds to a primal node
# this plays the analogous role as Dualvolumestruct in 3D
# to describe the highest-dimensional object in 2D
# and contains all lower dimensional objects
mutable struct Dualfacestruct_2D
    id::Int # primal node id

    interior_dualnodes::Vector{Int}
    boundary_dualnodes::Vector{SVector{2, Int}}

    interior_dualedges::Vector{SVector{2, Int}}
    boundary_dualedges::Vector{SVector{2, Int}}
    auxiliary_onprimaledge_dualedges::Vector{SVector{2, Any}}
    
    raw_area::Float64
    Dualfacestruct_2D() = new()
end


# declare struct to contain all dual node dicts in 2D
# same as Dualnodedicts_struct except no auxiliary_dualnodedict and 2D-compatible
# interior and boundary dual nodes as declared previously are used
mutable struct Dualnodedicts_struct_2D
    interior_dualnodedict_2D::Dict{Int, Interior_dualnodestruct_2D}
    boundary_dualnodedict_2D::Dict{SVector{2, Int}, Boundary_dualnodestruct_2D}
    Dualnodedicts_struct_2D() = new()
end


# declare struct to contain all dual edge dicts in _2D
# same as Dualedgedicts_struct except no auxiliary_onprimalface_dualedgedict and 2D-compatible
# interior, boundary, and auxiliary_onprimaledge dual edges as declared previously are used
mutable struct Dualedgedicts_struct_2D
    interior_dualedgedict_2D::Dict{SVector{2, Int}, Interior_dualedgestruct_2D}
    boundary_dualedgedict_2D::Dict{SVector{2, Int}, Boundary_dualedgestruct_2D}
    auxiliary_onprimaledge_dualedgedict_2D::Dict{SVector{2, Any}, Auxiliary_onprimaledge_dualedgestruct_2D}
    Dualedgedicts_struct_2D() = new()
end


# declare struct to contain all dual mesh dicts
# same as Dualmeshstruct except no dualvolumedict, 
# dualfacedicts is redefined,
# and 2D-compatible dual node and edge dicts as declared previously are used
mutable struct Dualmeshstruct_2D
    dualnodedicts_2D::Dualnodedicts_struct_2D
    dualedgedicts_2D::Dualedgedicts_struct_2D
    dualfacedict_2D::Dict{Int, Dualfacestruct_2D}
    Dualmeshstruct_2D() = new()
end


end
########################################### End dual mesh ###########################################

# test = Physicalname_struct()
# test.physicaltag = 1
# test.dimension = 2
# test.name = "test"
# 
# test
# 
# test = Point_entity_struct()