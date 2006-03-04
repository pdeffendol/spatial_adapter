require 'active_record'
require 'geo_ruby'

include GeoRuby::SimpleFeatures

module ActiveRecord
  module ConnectionAdapters
    class Column
      alias :original_type_cast :type_cast
      #Redefines type_cast to add support for geometries
      def type_cast(value)
        return nil if value.nil?
        case type
        when :geometry then self.class.string_to_geometry(value)
        else original_type_cast(value)
        end
      end

      alias :original_type_cast_code :type_cast_code
      #Redefines type_cast_code to add support for geometries. 
      #
      #WARNING : Since ActiveRecord seems to keep only the string values directly returned from the database, it translates from these to the correct types everytime an attribute is read (using the code returned by this method), which is probably ok for simple types, but might be less than efficient for geometries. Also you cannot modify the geometry object returned from an attribute directly :
      #
      # place = Place.find_first
      # place.the_geom.y=123456.7
      #
      #Since the translation to a geometry is performed everytime the_geom is read, the change to y will not be saved! You would have to do something like this :
      #
      # place = Place.find_first
      # the_geom = place.the_geom
      # the_geom.y=123456.7
      # place.the_geom = the_geom
      def type_cast_code(var_name)
        case type
        when :geometry then "#{self.class.name}.string_to_geometry(#{var_name})"
        else
          original_type_cast_code(var_name)
        end
      end

      alias :original_klass :klass
      #Redefines klass to add support for geometries
      def klass
        case type
          when :geometry then GeoRuby::SimpleFeatures::Geometry
          else original_klass
        end
      end

      #Transforms a string to a geometry
      def self.string_to_geometry(string)
        return string unless string.is_a?(String)
        begin
          GeoRuby::SimpleFeatures::Geometry.from_ewkb(string[4..-1])
        rescue Exception => exception
          nil
        end
      end
      
      private
      alias :original_simplified_type :simplified_type
      #Redefines the simplified_type method to add behabiour for when a column is of type geometry
      def simplified_type(field_type)
        case field_type
          when /geometry|point|linestring|polygon|multipoint|multilinestring|multipolygon|geometrycollection/i then :geometry
          else original_simplified_type(field_type)
        end
      end

    end

    class MysqlAdapter
      alias :original_quote :quote
      #Redefines the quote method to add behaviour for when a Geometry is encountered
      def quote(value, column = nil)
        if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
          "GeomFromWKB(0x#{value.as_hex_binary(2,false)},#{value.srid})"
        else
          original_quote(value,column)
        end
      end

      #Adds a geometry column, OGC-style. The table must use the MyISAM database engine. Authorized geometry types are :point, :line_string, :polygon, :geometry, :geometry_collection, :multi_point, :multi_line_string, :multi_polygon.
      def add_geometry_column(table_name,column_name,geometry_type,is_not_null)
        geometry_type = geometry_data_types[geometry_type]
        suffix=""
        suffix="NOT NULL" if is_not_null
        execute "ALTER TABLE #{table_name} ADD #{column_name} #{geometry_type} #{suffix}"
      end

      #Drops a geometry column, OGC-style.
      def drop_geometry_column(table_name,column_name)
        execute "ALTER TABLE #{table_name} DROP #{column_name}"
      end

      #Adds a spatial index to a geometric column. The column must be declared not null. Its name will be <table_name>_<column_name>_spatial_index unless the key :name is present in the options hash, in which case its value is taken as the name of the index.
      def add_spatial_index(table_name,column_name,options = {})
        index_name = "#{table_name}_#{column_name}_spatial_index"
        index_name = options[:name] || index_name
        execute "CREATE SPATIAL INDEX #{index_name} ON #{table_name} (#{column_name})"
      end

      #Translation of geometric data types
      def geometry_data_types
        {
          :point => "POINT",
          :line_string => "LINESTRING",
          :polygon => "POLYGON",
          :geometry_collection => "GEOMETRYCOLLECTION",
          :multi_point => "MULTIPOINT",
          :multi_line_string => "MULTILINESTRING",
          :multi_polygon => "MULTIPOLYGON",
          :geometry => "GEOMETRY"
        }
      end
    end
  end
end
