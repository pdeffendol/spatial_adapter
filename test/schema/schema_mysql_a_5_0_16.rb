require File.dirname(__FILE__) + '/../common/common.rb'

ActiveRecord::Schema.define() do

  create_table "table_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null=>false
  end

  create_table "table_line_strings", :force => true do |t|
    t.column "value", :integer
    t.column "geom", :line_string, :null=>false
  end
  
  create_table "table_polygons", :force => true do |t|
    t.column "geom", :polygon, :null=>false
  end

  create_table "table_multi_points", :force => true do |t|
    t.column "geom", :multi_point, :null=>false
  end
  
  create_table "table_multi_line_strings", :force => true do |t|
    t.column "geom", :multi_line_string, :null=>false
  end

  create_table "table_multi_polygons", :force => true do |t|
    t.column "geom", :multi_polygon, :null=>false
  end

  create_table "table_geometries",  :force => true do |t|
    t.column "geom", :geometry, :null=>false
  end

  create_table "table_geometry_collections", :force => true do |t|
    t.column "geom", :geometry_collection, :null=>false
  end
 
end




