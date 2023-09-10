module Mesher2D_Parse
export parsefile_2D

import FromFile: @from

# @from "../mesher3D/mesher3D_parse.jl" using Mesher3D_Parse: getfilepath, parsephysicalnames # (LOOK into why this is not working?)
# not included: parse_entities_2(), parsenodes_2(), parsetets(), parsefile()
using ..Mesher3D_Parse
using ..mesher2D_Types
# @from "mesher2D_types.jl" using mesher2D_Types

using StaticArrays
"""
    parse_entities_2_2D(fileinstance::IOStream)::All_entities_struct_2D

Return an dict of entities corresponding to the relevant
information of the "\$Entities" section in fileinstance.

Same as parse_entities_2(), but does not include volume entities and uses All_entities_struct_2D instead of All_entities_struct.
"""
function parse_entities_2_2D(fileinstance::IOStream)::All_entities_struct_2D

    # instantiate empty struct to populate
    all_entities_struct_2D = All_entities_struct_2D()

    # 1st line after $Entities gives number of entities of each category
    currentline = readline(fileinstance)
    entities_data = parse.(Int, split(strip(currentline), " "))
    num_points = entities_data[1]
    num_curves = entities_data[2]
    num_surfaces = entities_data[3]

    # create dictionary of point entities
    point_entities_dict = Dict{Int, Point_entity_struct}()
    for _ in 1:num_points

        currentline = readline(fileinstance)
        entitydata = split(strip(currentline), " ")
        point_tag = parse(Int, entitydata[1])
        num_physicaltags = parse(Int, entitydata[5])
        
        physicaltags = []
        if num_physicaltags != 0
            append!(physicaltags, parse.(Int, entitydata[6:6+num_physicaltags-1]))
        end

        point_entity_struct = Point_entity_struct()
        point_entity_struct.point_tag = point_tag
        point_entity_struct.physicaltags = physicaltags

        point_entities_dict[point_tag] = point_entity_struct

    end

    # create dictionary of curve entities
    curve_entities_dict = Dict{Int, Curve_entity_struct}()
    for _ in 1:num_curves

        currentline = readline(fileinstance)
        entitydata = split(strip(currentline), " ")
        curve_tag = parse(Int, entitydata[1])
        num_physicaltags = parse(Int, entitydata[8])
        num_boundingPoints = parse(Int, entitydata[9+num_physicaltags])

        physicaltags = []
        if num_physicaltags != 0
            append!(physicaltags, parse.(Int, entitydata[9:9+num_physicaltags-1]))
        end

        boundingPoints = []
        bnd_pts_startind = 9+num_physicaltags+1
        append!(boundingPoints, abs.(parse.(Int, entitydata[bnd_pts_startind:bnd_pts_startind+num_boundingPoints-1])))

        curve_entity_struct = Curve_entity_struct()
        curve_entity_struct.curve_tag = curve_tag
        curve_entity_struct.physicaltags = physicaltags
        curve_entity_struct.boundingpoints = boundingPoints

        curve_entities_dict[curve_tag] = curve_entity_struct

    end

    # create dictionary of surface entities
    surface_entities_dict = Dict{Int, Surface_entity_struct}()
    for _ in 1:num_surfaces

        currentline = readline(fileinstance)
        entitydata = split(strip(currentline), " ")
        surface_tag = parse(Int, entitydata[1])
        num_physicaltags = parse(Int, entitydata[8])
        num_boundingCurves = parse(Int, entitydata[9+num_physicaltags])

        physicaltags = []
        if num_physicaltags != 0
            append!(physicaltags, parse.(Int, entitydata[9:9+num_physicaltags-1]))
        end

        boundingCurves = []
        bnd_curves_startind = 9+num_physicaltags+1
        append!(boundingCurves, abs.(parse.(Int, entitydata[bnd_curves_startind:bnd_curves_startind+num_boundingCurves-1])))

        surface_entity_struct = Surface_entity_struct()
        surface_entity_struct.surface_tag = surface_tag
        surface_entity_struct.physicaltags = physicaltags
        surface_entity_struct.boundingcurves = boundingCurves

        surface_entities_dict[surface_tag] = surface_entity_struct

    end

    # insert dicts into struct
    all_entities_struct_2D.point_entities_dict = point_entities_dict
    all_entities_struct_2D.curve_entities_dict = curve_entities_dict
    all_entities_struct_2D.surface_entities_dict = surface_entities_dict

    return all_entities_struct_2D

end



"""
    parsenodes(fileinstance::IOStream)

Return a dict of Nodestruct corresponding to the "\$Nodes" section in fileinstance.

Reads fileinstance line by line.

Same as parsenodes_2() but uses All_entities_struct_2D instead of All_entities_struct.
"""
function parsenodes_2_2D(fileinstance::IOStream, all_entities_struct_2D::All_entities_struct_2D)::Dict{Int64, Nodestruct}

    # instantiate empty dict to populate with structs
    nodedict = Dict{Int, Nodestruct}()
    
    # 1st line after $Nodes contains metadata about section
    currentline = readline(fileinstance)
    nodesdata = parse.(Int, split(strip(currentline), " "))
    num_node_entities = nodesdata[1]
    # num_nodes = nodesdata[2]

    for _ in 1:num_node_entities
        
        # 1st line of each block contains meta-data about entity
        currentline = readline(fileinstance) 
        entitydata = parse.(Int, split(strip(currentline), " "))
        root_entitydim = entitydata[1] # MshFileVersion 4.1
        root_entityid = entitydata[2] # index of the entity (MshFileVersion 4.1)
        num_nodes_inentity = entitydata[4]

        # list of all node tags in this entity
        current_tags = Vector{Int}() 
        
        # if entity has x nodes, first x lines after 
        # entity meta-data contains all node tags in this entity
        for _ in 1:num_nodes_inentity
            
            currentline = readline(fileinstance)
            tag = parse.(Int, currentline)
            push!(current_tags, tag)
        
        end

        for nodeid in current_tags

            currentline = readline(fileinstance)
            nodecoords = parse.(Float64, split(strip(currentline), " ")) 
            nodecoords = convert(SVector{3, Float64}, nodecoords)

            entities_dict = Dict{Int,Vector{}}()
            # from the root entity, find all higher-dim entities that this node belongs to
            if root_entitydim == 0
                curvetags = []
                for kcurve in keys(all_entities_struct_2D.curve_entities_dict)
                    if root_entityid in all_entities_struct_2D.curve_entities_dict[kcurve].boundingpoints
                        append!(curvetags, kcurve)
                    end
                end
                surfacetags = []
                for ksurface in keys(all_entities_struct_2D.surface_entities_dict)
                    for kcurve in curvetags
                        if (kcurve in all_entities_struct_2D.surface_entities_dict[ksurface].boundingcurves)&&!(ksurface in surfacetags)
                            append!(surfacetags, ksurface)
                        end
                    end
                end
                entities_dict[1] = curvetags
                entities_dict[2] = surfacetags
            elseif root_entitydim == 1
                surfacetags = []
                for ksurface in keys(all_entities_struct_2D.surface_entities_dict)
                    if (root_entityid in all_entities_struct_2D.surface_entities_dict[ksurface].boundingcurves)&&!(ksurface in surfacetags)
                        append!(surfacetags, ksurface)
                    end
                end
                entities_dict[1] = [root_entityid]
                entities_dict[2] = surfacetags
            elseif root_entitydim == 2
                entities_dict[1] = [0]
                entities_dict[2] = [root_entityid]
            end
            # create a Nodestruct
            node = Nodestruct()
            node.id = nodeid
            node.coords = nodecoords
            node.root_entitydim = root_entitydim
            node.root_entityid  = root_entityid
            node.entities_dict  = entities_dict
            # update nodedict
            nodedict[nodeid] = node

        end 

    end

    return nodedict

end


"""
    parsefaces_2D(nodedict::Vector{Nodestruct}, fileinstance::IOStream)

Return a dict of structs of Facestruct_2D corresponding to the "\$Elements" section in fileinstance.

Reads fileinstance line by line.
"""
function parsefaces_2D(fileinstance::IOStream)::Dict{Int, Facestruct_2D}

    # instantiate empty dict to populate with structs
    facedict_2D = Dict{Int, Facestruct_2D}()

    # 1st line after $elements contains metadata about section
    currentline = readline(fileinstance)
    elementsdata = parse.(Int, split(strip(currentline), " "))
    num_element_entities = elementsdata[1]
    num_elements_inentity = elementsdata[2]

    for _ in 1:num_element_entities
        
        # 1st line of each block contains meta-data about entity
        currentline = readline(fileinstance) 
        entitydata = parse.(Int, split(strip(currentline), " "))
        entityid = entitydata[2]
        elementtype = entitydata[3]
        num_elements_inentity = entitydata[4]

        if elementtype == 2 #(i.e. a 3-node triangle)
            
            for _ in 1:num_elements_inentity

                currentline = readline(fileinstance)
                currentline_parsed = parse.(Int, split(strip(currentline), " "))
                elementtag = currentline_parsed[1]
                element_nodeids = currentline_parsed[2:end] # 4 Ints

                # create a Facestruct_2D
                face_2D = Facestruct_2D()

                face_2D.id = elementtag
                face_2D.nodes = element_nodeids
                face_2D.entityid = entityid

                # update facedict_2D
                facedict_2D[elementtag] = face_2D
                
            end

        else
            for _ in 1:num_elements_inentity
                currentline = readline(fileinstance)
            end
        end
    
    end

    return facedict_2D

end 


"""
    parsefile_2D(file::String)

Return the dictionaries of nodes, faces_2D, physical names, and entities.

Reads the .msh file line by line and calls the appropriate section
parser.

Same as parsefile() but replaced All_entities_struct with All_entities_struct_2D,

"""
function parsefile_2D(file::String)::Vector{Any}

    physicalnames_dict = Dict{Int, Physicalname_struct}()
    all_entities_struct_2D = All_entities_struct_2D()
    nodedict = Dict{Int, Nodestruct}()
    facedict_2D = Dict{Int, Facestruct_2D}()

    # get full file path of .msh file
    meshpath = getfilepath(file)

    # parse file
    currentline = "init" 
    open(meshpath) do fileinstance

        while !eof(fileinstance)

            if startswith(currentline, "\$PhysicalNames")
                physicalnames_dict = parsephysicalnames(fileinstance)
            elseif startswith(currentline, "\$Entities")
                all_entities_struct_2D = parse_entities_2_2D(fileinstance)
            elseif startswith(currentline, "\$Nodes")
                nodedict = parsenodes_2_2D(fileinstance, all_entities_struct_2D)
            elseif startswith(currentline, "\$Elements")
                facedict_2D = parsefaces_2D(fileinstance)
            end
            currentline = readline(fileinstance)

        end

    end

    return [nodedict, facedict_2D, physicalnames_dict, all_entities_struct_2D]

end

end

# 
# test
@from "mesher2D_parse.jl" using Mesher2D_Parse
# parsefile_2D("../meshes/triangles_test.msh")
Mesher2D_Parse.parsefile_2D("/meshes/triangles_test.msh")

#test