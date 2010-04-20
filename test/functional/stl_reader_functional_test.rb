require 'test/unit'
require 'tools/readers/stl_reader.rb'

class StlReaderFunctionalTest < Test::Unit::TestCase
  # def setup
  # end
  
  # def teardown
  # end
  
  def test_for_each_triangle
    triangles_decoded=false
    @reader = StlReader.new(File.new("test/data/stl_reader/binary_test.stl", "rb"),nil)
    count = 0

    @reader.for_each_triangle do |triangle|
      count += 1
      triangle.vertices.each do |v1|
        v1.each do |scal1|
          assert(!(scal1.nan? || scal1.infinite?), 'bad triangle vertex detected: '+scal1.to_s)
        end
      end
      #puts(triangle.verticies[0][0])
      triangles_decoded=true
    end

    assert(triangles_decoded, 'Failed to decode triangles')
  end

  def test_to_layered_model
    triangles_decoded=false
    @reader = StlReader.new(File.new("test/data/stl_reader/binary_test.stl", "rb"),nil)
    count = 0

    @reader.to_layered_model.layers.each do |layer|
      layer.primitives.each do |line|
        count += 1
        line.vertices.each do |v1|
          v1.each do |scal1|
            assert(!(scal1.nan? || scal1.infinite?), 'bad layer line vertex detected: '+scal1.to_s)
          end
        end
        puts(line.vertices[0][0])
        triangles_decoded=true
      end
    end
  end
    
  def test_gcode_generator
    @reader = StlReader.new(File.new("test/data/stl_reader/frame-vertex_6off.stl", "rb"),nil)

    puts("starting gcode..")
    File.open("test/data/stl_reader/binary_test.gcode", 'w') do |f|
      f.write("M104 S220 T0 (Temperature to 220 celsius)
G21 (Metric FTW)
G90 (Absolute Positioning)
G92 X0 Y0 Z0 (You are now at 0,0,0)
G0 Z15 (Move up for test extrusion)
M108 S255 (Extruder speed = max)
M6 T0 (Wait for tool to heat up)
G04 P5000 (Wait 5 seconds)
M101 (Extruder on, forward)
G04 P5000 (Wait 5 seconds)
M103 (Extruder off)
M01 (The heater is warming up and will do a test extrusion.  Click yes after you have cleared the nozzle of the extrusion.)
G0 Z0 (Go back to zero.)
G90
G21
M103
M108 S255.0
M104 S230.0\n")
      @reader.to_layered_model.layers.each do |layer|
        puts("paths "+layer.closed_paths.to_s)
        if (layer.closed_paths == nil)
          put "no closed paths"
          return
        else
        layer.closed_paths.each do |path_lines|
          puts("path"+path_lines.to_s)
          path_lines.each do |line|
            #Primative GCode. Does not follow outlines. Highly inefficient, but for test purposes accurate.
  #          f_value = "0"
            f_value = "1560"
            draw = false
            line.vertices.each do |vert|
  #            if !(vert[0].nan? || vert[0].infinite?) then
                #f.write((draw==true)?"m101\n":"m103\n")
                f.write("m103\n")
                f.write("G1 X"+vert[0].to_s+" Y"+vert[1].to_s+" Z"+vert[2].to_s+" F"+f_value+"\r\n") #F here is arbitrary for testing
                draw = true
  #              f_value = "1560"
  #            else
  #              puts("G1 X"+vert[0].to_s+" Y"+vert[1].to_s+" Z"+vert[2].to_s+" F1560.0\r\n") #F here is arbitrary for testing
  #            end
            end
          end
        end
      end
      end
    end
    puts("gcode done.")
  end
end