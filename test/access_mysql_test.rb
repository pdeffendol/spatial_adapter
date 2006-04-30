require 'test/unit'
require 'common/common_mysql'
require 'models/models_mysql'


class FileColumTest < Test::Unit::TestCase
   
  def test_point
    pt = TablePoint.new(:data => "Test", :geom => Point.from_x_y(1.2,4.5))
    assert(pt.save)
    
    pt = TablePoint.find_first
    assert(pt)
    assert_equal("Test",pt.data)
    assert_equal(Point.from_x_y(1.2,4.5),pt.geom)
    
  end

  def test_line_string
    ls = TableLineString.new(:value => 3, :geom => LineString.from_coordinates([[1.4,2.5],[1.5,6.7]]))
    assert(ls.save)
    
    ls = TableLineString.find_first
    assert(ls)
    assert_equal(3,ls.value)
    assert_equal(LineString.from_coordinates([[1.4,2.5],[1.5,6.7]]),ls.geom)
    
  end


end
