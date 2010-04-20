class CadModel
  attr_accessor :layers
  
  def initialize(layer_stepping)
    @layer_stepping = layer_stepping
    @layers = Array.new()
  end
  
  def getLayer(layerIndex)
    return @layers.get(layerIndex)
  end
  
  def add_primitive(layerIndex, primitive)
    if @layers[layerIndex]==nil then
      @layers[layerIndex] = CADModelLayer.new
    end
    @layers[layerIndex].primitives.push(primitive)
  end

end

class CADModelLayer
  #An unordered array of 2d primitives in this layer
  attr_accessor :primitives
  #A closed-loop consists of a series of connected unique geometric primitives that if traversed go from point A to point A
  attr_accessor :closed_paths
  
  def initialize
     @primitives = Array.new
     @loops= Array.new
 end
end
