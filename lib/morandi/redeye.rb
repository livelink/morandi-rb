module Morandi
module RedEye
module TapRedEye
  module_function
  def tap_on(pb, x, y)
    n = ([pb.height,pb.width].max / 10)
    x1  = [x - n, 0].max
    x2  = [x + n, pb.width].min
    y1  = [y - n, 0].max
    y2  = [y + n, pb.height].min
    return pb unless (x1 >= 0) && (x2 > x1) && (y1 >= 0) && (y2 > y1)
    redeye = RedEye.new(pb, x1, y1, x2, y2)

    sensitivity = 2
    blobs = redeye.identify_blobs(sensitivity).reject { |i|
      i.noPixels < 4 or ! i.squareish?(0.5, 0.4)
    }.sort_by { |i|
      i.area_min_x = x1
      i.area_min_y = y1

      # Higher is better
      score = (i.noPixels) / (i.distance_from(x, y) ** 2)
    }

    #blobs.each do |blob|
    #  p [ [x, y], blob.centre(), blob.distance_from(x, y), blob]
    #end

    blob = blobs.last
    redeye.correct_blob(blob.id) if blob
    pb = redeye.pixbuf
  end
end
end
end

class ::RedEye::Region
  attr_accessor :area_min_x
  attr_accessor :area_min_y
  def centre
    [@area_min_x.to_i + ((maxX + minX) >> 1),
     @area_min_y.to_i + ((maxY + minY) >> 1)]
  end

  # Pythagorean
  def distance_from(x,y)
    cx,cy = centre()

    dx = cx - x
    dy = cy - y

    Math.sqrt( (dx * dx) + (dy * dy) )
  end
end

