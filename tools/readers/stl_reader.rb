require 'rubygems'
require 'float-formats'
require 'engine/geometry/triangle.rb'
require 'engine/cad_model.rb'
require 'engine/linked_list.rb'
include Flt

class StlReader
  
  def initialize(io_stream, config)
    @io_stream = io_stream
    #TODO: config loaded parameters
    @layerStepping = 1
  end
  
  # Returns the layered model for this PolygonBasedCadReader
  def to_layered_model(includePlanarTriangles = false, includeClosedPaths = true)
    model = CadModel.new(@layerStepping)
    
    for_each_triangle do |triangle|
      #Triangle vertices sorted from bottom [0] to top [2] and snapped to the discrete layer increments
      verts = triangle.vertices.each{|v|
        stepMod = v[Z]%@layerStepping
        v[Z] = (stepMod>@layerStepping/2)? v[Z]+stepMod : v[Z]-stepMod
      }
      verts = verts.sort{|v1,v2| v1[Z] <=> v2[Z]}
      
      if verts[0][Z] == verts[2][Z] then
        if includePlanarTriangles==true then
          #== finding the layer-planar lines of a layer-planar triangle ==
          [verts[0..1],verts[1..2],[verts[2],verts[0]]].each do |vert_set|
            line = Line.new
            line.vertices = vert_set
            model.add_primitive(verts[0][Z], line)
          end
        end
      else
        #== finding the layer-planar intersections of the non-planar triangle (in the form of line segments) ==

        #identify the 3 lines of the triangle
        tall_line = get_slope(verts[0], verts[2])
        short_line_verts = [[verts[1], verts[2]], [verts[0], verts[1]]]
      
        #get layer information for each half triangle
        short_line_verts.each do |short_vert|
          if (short_vert[0][Z] == short_vert[1][Z])
            #layer planar short lines
            line = Line.new
            line.vertices = short_vert[0..1]
            model.add_primitive(Integer(short_vert[0][Z]), line)
          else
            #layer non-planar short lines
            short_line = get_slope(short_vert[0], short_vert[1])
            #TODO: implement actual step size configuration (vs. forced to use 1 due to integer rounding)
            bottom_z_plane = Integer(short_vert[0][Z]);
            #iterating through each integer layer between the bottom and the top of the half triangle
            (0..Integer(short_vert[1][Z])-bottom_z_plane).each do |layer_index|
              #input non-layer planar triangle lines
              lines = [short_line, tall_line]
              start_Points = [short_vert[0], verts[0]]
              #output layer planar line
              layer_planar_line = Line.new()
              #generating the layer 2d line (planar) from the half triangle from the combination of the 2 input lines
              [0,1].each do |line_index|
                layer_planar_line.vertices[line_index] = Array.new
                [X,Y].each do |axis|
                  layer_planar_line.vertices[line_index][axis] = lines[line_index][axis]*layer_index+start_Points[line_index][axis] #slope of [X, Y] * Z
                end
                layer_planar_line.vertices[line_index][Z] = Float(layer_index+bottom_z_plane)
              end
              model.add_primitive(layer_index+bottom_z_plane, layer_planar_line)
            end
          end
        end
      end
      #TODO: finding the layer closed-loop curves
    end
    
    #Closed Path calculation
    if includeClosedPaths == true then
      model.layers.each do |layer|
        vert_hash = {}
        unique_paths = [] # a array of unique paths which in valid stl will be closed paths once each vert has been added
        
        #indexing each line by it's vertices in the hash and simultaneously creating traversable paths via arrays of 
        #connected lines.
        layer.primitives.each do |line|
          #path_ref format: [this vertex's containing path array, this vertex's path array index]
          #these are pointers for the line on each path containing it's vertices
          path_refs = line.vertices.collect{|vert| vert_hash[vert]}
          
          #New: Creating a new traversable vertex path as an array starting with this line.
          if (path_refs[0] == nil && path_refs[1] == nil)
            puts("new")
            new_path_ref = [[line],0]
            unique_paths.push(new_path_ref[0])
            line.vertices.each {|vert| vert_hash[vert] = new_path_ref}
          #Merge: Merge the two existing vertex paths at each of this line's vertices and update the hash.
          elsif (path_refs[0] != nil && path_refs[1] != nil)
            puts("merge")
            s = (path_refs[0][1] == path_refs[0][0].size-1)? [0,1] : [1,0] #the sort for the traversed order of the paths
            vert_hash[line.vertices[s[1]]] = [path_refs[s[0]][0], path_refs[s[0]][1]] #update the merged path's path_ref
            unique_paths.delete(path_refs[1][0]) #remove the merged path from the unique paths
#            path_refs[s[0]][0].push(line).concat(path_refs[s[1]][0])
#        end
#        puts("working..")
#        sleep(1)
#        sleep(0.1)
#=begin
            
          #Add: Appending the line to it's vertex's existing path array
        else
            puts("add")
            [0,1].each do |i|
              if path_refs[i]!=nil then
                line_index = (path_refs[i][1]==path_refs[i][0].size-1)? path_refs[i][1]+1 : path_refs[i][1]-1
                path_refs[i][0][line_index] = line #add the line to the path
                vert_hash[ line.vertices[(i==0)?1:0] ] = [path_refs[i][0],line_index] #index the new vertex
              end
            end
          end
#=end
        end
        layer.closed_paths = unique_paths #probably atomic, not that it should matter for a long time to come
        layer.closed_paths = [layer.primitives[0..4]] #probably atomic, not that it should matter for a long time to come
      end
   end
    
    return model
  end
  
  #decodes each triangle from the input file.
  def for_each_triangle
    #assumed to be binary stl
    attribute_bytes = 2 #defaulting to 2. TODO: if necessary: calculate based on (facet bytes - 84) / file size - 4*12
    
    #skip the 80 header bytes + 4 # of facet bytes
    @io_stream.read(84)
    #read the triangle data
    while @io_stream.eof==false
      triangle = Triangle.new()
      
      #read the verticies of the triangle -> (3 verticies + 1 normal) x 3 axis x 4 bites per float = 48 bytes
      triangle_data = (@io_stream.read(48)).unpack("f*")
      
      #discarding the attribute bytes
      @io_stream.read(attribute_bytes)
      
      #read the triangle's normal vector - this points outward from the object
      triangle.normal = triangle_data[0..2]
      
      #interpretting the data
      for vertex in (0..2)
        offset = (vertex+1)*3
        triangle.vertices[vertex] = triangle_data[(offset)..(offset+2)]
      end
      
      yield(triangle)
    end
  end
end