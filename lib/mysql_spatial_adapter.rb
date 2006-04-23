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
      #Redefines the simplified_type method to add behabiour for when a column is of type geometry ; It should be enough to simplify all geometric types to :geometry. Unfortunately, if db:schema:dump is used (like for example during tests, when the database is regenerated), the dumped type for any of these geometric types will be :geometry. Maybe it is ok? It would simplify the code a little bit.
      def simplified_type(field_type)
        case field_type
          when /point|linestring|polygon|geometry|multipoint|multilinestring|multipolygon|geometrycollection/i then :geometry
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

      alias :original_native_database_types :native_database_types
      def native_database_types
        original_native_database_types.merge!(:point => { :name => "POINT" },
          :line_string => { :name => "LINESTRING" },
          :polygon => { :name => "POLYGON" },
          :geometry_collection => { :name => "GEOMETRYCOLLECTION" },
          :multi_point => { :name => "MULTIPOINT" },
          :multi_line_string => { :name => "MULTILINESTRING" },
          :multi_polygon => { :name => "MULTIPOLYGON" },
          :geometry => { :name => "GEOMETRY"})
      end

      #if the :spatial key in the options table is true, then the sql string for a spatial index is created
      def add_index(table_name,column_name,options = {})
        index_name = options[:name] || "#{table_name}_#{Array(column_name).first}_index"
        
        if options[:spatial]
          #one by one
          Array(column_name).each do |col|
            index_name = "#{table_name}_#{column_name}_index" if Array(column_name).length >0
            execute "CREATE SPATIAL INDEX #{index_name} ON #{table_name} (#{Array(column_name).join(", ")})"
          end
        else
          index_type = options[:unique] ? "UNIQUE" : ""
          #all together
          execute "CREATE #{index_type} INDEX #{index_name} ON #{table_name} (#{Array(column_name).join(", ")})"
        end
      end
      
    end
  end
end



