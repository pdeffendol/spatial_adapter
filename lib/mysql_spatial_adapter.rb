require 'active_record'
require 'geo_ruby'
require 'common_spatial_adapter'

include GeoRuby::SimpleFeatures


#add a method to_fixture_format to the Geometry class which will transform a geometry in a form suitable to be used in a YAML file (such as in a fixture)
GeoRuby::SimpleFeatures::Geometry.class_eval do
  def to_fixture_format
    "!binary | #{[(255.chr * 4) + as_wkb].pack('m')}"
  end
end


ActiveRecord::Base.class_eval do
  #Redefinition of the method to do something special when a geometric column is encountered
  def self.construct_conditions_from_arguments(attribute_names, arguments)
    conditions = []
    attribute_names.each_with_index do |name, idx| 
      if columns_hash[name].is_a?(SpatialColumn)
        #when the discriminating column is spatial, always use the MBRIntersects (bounding box intersection check) operator : the user can pass either a geometric object (which will be transformed to a string using the quote method of the database adapter) or an array with the corner points of a bounding box
        if arguments[idx].is_a?(Array)
          conditions << "MBRIntersects(?, #{table_name}.#{connection.quote_column_name(name)}) "
          #using some georuby utility : The multipoint has a bbox whose corners are the 2 points passed as parameters : [ pt1, pt2]
          arguments[idx]= MultiPoint.from_coordinates(arguments[idx])
        else
          conditions << "MBRIntersects(?, #{table_name}.#{connection.quote_column_name(name)}) " 
        end
      else
        conditions << "#{table_name}.#{connection.quote_column_name(name)} #{attribute_condition(arguments[idx])} " 
      end
    end
    [ conditions.join(" AND "), *arguments[0...attribute_names.length] ]
  end
end


ActiveRecord::ConnectionAdapters::MysqlAdapter.class_eval do
  
  include SpatialAdapter

  alias :original_native_database_types :native_database_types
  def native_database_types
    original_native_database_types.merge!(geometry_data_types)
  end
 
  alias :original_quote :quote
  #Redefines the quote method to add behaviour for when a Geometry is encountered ; used when binding variables in find_by methods
  def quote(value, column = nil)
    if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
      "GeomFromWKB(0x#{value.as_hex_wkb},#{value.srid})"
    else
      original_quote(value,column)
    end
  end
  
  #Redefinition of columns to add the information that a column is geometric
  def columns(table_name, name = nil)#:nodoc:
    sql = "SHOW FIELDS FROM #{table_name}"
    columns = []
    execute(sql, name).each do |field| 
      if field[1] =~ /geometry|point|linestring|polygon|multipoint|multilinestring|multipolygon|geometrycollection/i
        #to note that the column is spatial
        columns << ActiveRecord::ConnectionAdapters::SpatialMysqlColumn.new(field[0], field[4], field[1], field[2] == "YES")
      else
        columns << ActiveRecord::ConnectionAdapters::MysqlColumn.new(field[0], field[4], field[1], field[2] == "YES")
      end
    end
    columns
  end


  #operations relative to migrations

  #Redefines add_index to support the case where the index is spatial
  #If the :spatial key in the options table is true, then the sql string for a spatial index is created
  def add_index(table_name,column_name,options = {})
    index_name = options[:name] || "#{table_name}_#{Array(column_name).first}_index"
    
    if options[:spatial]
      if column_name.is_a?(Array) and column_name.length > 1
        #one by one or error : Should raise exception instead? ; use default name even if name passed as argument
        Array(column_name).each do |col|
          execute "CREATE SPATIAL INDEX #{table_name}_#{col}_index ON #{table_name} (#{col})"
        end
      else
        col = Array(column_name)[0]
        execute "CREATE SPATIAL INDEX #{index_name} ON #{table_name} (#{col})"
      end
    else
      index_type = options[:unique] ? "UNIQUE" : ""
      #all together
      execute "CREATE #{index_type} INDEX #{index_name} ON #{table_name} (#{Array(column_name).join(", ")})"
    end
  end

  #Check the nature of the index : If it is SPATIAL, it is indicated in the IndexDefinition object (redefined to add the spatial flag in spatial_adapter_common.rb)
  def indexes(table_name, name = nil)#:nodoc:
    indexes = []
    current_index = nil
    execute("SHOW KEYS FROM #{table_name}", name).each do |row|
      if current_index != row[2]
        next if row[2] == "PRIMARY" # skip the primary key
        current_index = row[2]
        indexes << ActiveRecord::ConnectionAdapters::IndexDefinition.new(row[0], row[2], row[1] == "0", row[10] == "SPATIAL",[])
      end
      indexes.last.columns << row[4]
    end
    indexes
  end
        
  #Get the table creation options : Only the engine for now. The text encoding could also be parsed and returned here.
  def options_for(table)
    result = execute("show table status like '#{table}'")
    engine = result.fetch_row[1]
    if engine !~ /inno/i #inno is default so do nothing for it in order not to clutter the migration
      "ENGINE=#{engine}" 
    else
      nil
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    class SpatialMysqlColumn < MysqlColumn

      include SpatialColumn
      
      #MySql-specific geometry string parsing. By default, MySql returns geometries in strict wkb format with "0" characters in the first 4 positions.
      def self.string_to_geometry(string)
        return string unless string.is_a?(String)
        begin
          GeoRuby::SimpleFeatures::Geometry.from_ewkb(string[4..-1])
        rescue Exception => exception
          nil
        end
      end
    end
  end
end
