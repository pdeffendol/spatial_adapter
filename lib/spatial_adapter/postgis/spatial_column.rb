require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class SpatialPostgreSQLColumn < PostgreSQLColumn
      include SpatialAdapter::SpatialColumn

      #Transforms a string to a geometry. PostGIS returns a HewEWKB string.
      def self.string_to_geometry(string)
        return string unless string.is_a?(String)
        GeoRuby::SimpleFeatures::Geometry.from_hex_ewkb(string) rescue nil
      end

      def self.create_simplified(name,default,null = true)
        new(name,default,"geometry",null,nil,nil,nil)
      end
    end
  end
end
