require 'geo_ruby'
require 'active_record'

require 'spatial_adapter/raw_geom_info'
require 'spatial_adapter/common/schema_definitions'
require 'spatial_adapter/postgis'

module SpatialAdapter
  #Translation of geometric data types
  def geometry_data_types
    {
      :point => { :name => "POINT" },
      :line_string => { :name => "LINESTRING" },
      :polygon => { :name => "POLYGON" },
      :geometry_collection => { :name => "GEOMETRYCOLLECTION" },
      :multi_point => { :name => "MULTIPOINT" },
      :multi_line_string => { :name => "MULTILINESTRING" },
      :multi_polygon => { :name => "MULTIPOLYGON" },
      :geometry => { :name => "GEOMETRY"}
    }
  end
end
