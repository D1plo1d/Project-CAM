require('Shoes')

def view_layer_locally
  Shoes.app do
     ox = nil
      oy = nil
     animate 24 do
       b, x, y = self.mouse
       line(ox, oy, x, y)  if b == 1
       ox, oy = x, y
     end
  end
end