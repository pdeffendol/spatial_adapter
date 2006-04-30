require File.dirname(__FILE__) + '/../common/common_postgis.rb'

#add some postgis specific tables
ActiveRecord::Schema.define() do

  create_table "table_3dz_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null => false , :with_z => true
  end

  create_table "table_3dm_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null => false , :with_m => true
  end

  create_table "table_4d_points", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null => false, :with_m => true, :with_z => true
  end

   create_table "table_srid_line_strings", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :null => false , :srid => 123
  end

  create_table "table_srid_4d_polygons", :force => true do |t|
    t.column "data", :string
    t.column "geom", :point, :with_m => true, :with_z => true, :srid => 123
  end
 
end




