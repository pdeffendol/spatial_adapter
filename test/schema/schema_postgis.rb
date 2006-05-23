require File.dirname(__FILE__) + '/../common/common_postgis.rb'

#add some postgis specific tables
ActiveRecord::Schema.define() do

  create_table "table_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null=>false
  end

  create_table "table_keyword_column_points", :force => true do |t|
    t.column "location", :point, :null => false
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

  create_table "table_geometries", :force => true do |t|
    t.column "geom", :geometry, :null=>false
  end

  create_table "table_geometry_collections", :force => true do |t|
    t.column "geom", :geometry_collection, :null=>false
  end

  create_table "table3dz_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null => false , :with_z => true
  end

  create_table "table3dm_points", :force => true do |t|
    t.column "geom", :point, :null => false , :with_m => true
  end

  create_table "table4d_points", :force => true do |t|
    t.column "geom", :point, :null => false, :with_m => true, :with_z => true
  end

   create_table "table_srid_line_strings", :force => true do |t|
    t.column "geom", :line_string, :null => false , :srid => 123
  end

  create_table "table_srid4d_polygons", :force => true do |t|
    t.column "geom", :polygon, :with_m => true, :with_z => true, :srid => 123
  end
 
end




