#this file shows how to use the migration feature of GeoRuby to create tables with geometric columns. Put this kind of code in the self.up method of a migration
class Abc < ActiveRecord::Migration
  def self.up

    #the Engine option is necessary if your mysql version is < 5.0.16
    create_table "places", :options => "ENGINE=MyISAM", :force=> true do |t|
      t.column "geom", :polygon, :null => false #like any other base type column
      t.column "data", :integer
    end
    
    add_index "places", "geom", :name => "places_geom_index", :spatial=>true
    
    add_column "places", "geom2", :point
    remove_column "places", "geom2"
    
  end
  
  def self.down
    drop_table("places")
  end
end
