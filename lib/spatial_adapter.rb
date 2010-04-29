# This file should typically not be directly require'd into your project. You
# should require the database-specific adapter you desire, e.g.
#
#   require 'spatial_adapter/postgresql'
#
# Why is this file here?
#
# Mostly to keep Rails happy when using config.gem to specify dependencies.
# The Rails init code (rails/init.rb) will then load the adapter that matches
# your database.yml configuration.

require 'geo_ruby'
require 'active_record'

include GeoRuby::SimpleFeatures

module SpatialAdapter
  # Translation of geometric data types
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
  
  class NotCompatibleError < ::StandardError
  end
end

require 'spatial_adapter/common/raw_geom_info'
require 'spatial_adapter/common/spatial_column'
require 'spatial_adapter/common/schema_definitions'
require 'spatial_adapter/common/schema_dumper'
require 'spatial_adapter/common/table_definition'
require 'spatial_adapter/railtie' if defined?(Rails::Railtie)
