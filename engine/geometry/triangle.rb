#TODO: This should be moved to the CAD module
X = 0
Y = 1
Z = 2
CARTESIAN_AXES = [X,Y,Z]

#A triangle consists of 3 verticies and an optional normal vector
class Triangle
  attr_accessor :normal
  attr_accessor :vertices
  
  def initialize()
    @vertices = Array.new 3
  end
end

class Line
  attr_accessor :vertices
  
  def initialize()
    @vertices = Array.new(2)
  end
end

#Returns an array of X, Y, Z slopes normalized to a Z slope of 1. A slope of Z of zero results in a error.
def get_slope startV, endV
  slope = Array.new
  #Computing the slopes
  CARTESIAN_AXES.each do |axis|
    slope[axis] = endV[axis] - startV[axis]
  end
  if slope[Z] == 0 then
    raise "zero Z slope not expected."
  end
  #Normalizing the X and Y slopes to a Z slope of 1
  [X,Y].each do |axis|
    slope[axis] = slope[axis]/slope[Z]
  end
  slope[Z] = 1
  return slope
end
