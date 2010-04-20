require 'ruby-processing'

class LayerView < Processing::App
  load_libraries :opengl, :boids
  # We need the OpenGL classes to be included here.
  include_package "processing.opengl"

  def setup
    size 640, 360, P3D
    lights
    @a = 0
  end
  
  def draw
    #Setup
    background 255, 255, 255
    translate width/2, height/2
    rotateX 45
    
    #Rotation
    a += 0.01
    if @a>=PI*2 then a = 0 end
    rotateZ @a
    #Drawing
    line -100,100,100,100
    line -100,-100,100,-100
  end
end