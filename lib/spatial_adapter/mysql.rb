require 'spatial_adapter'
require 'spatial_adapter/base/mysql'
require 'active_record/connection_adapters/mysql_adapter'

module ActiveRecord::ConnectionAdapters
  class MysqlAdapter
    include SpatialAdapter::Base::Mysql::Adapter

    #Redefinition of columns to add the information that a column is geometric
    def columns(table_name, name = nil)#:nodoc:
      result = show_fields_from(table_name, name)

      columns = []
      result.each do |field|
        klass = \
          if field[1] =~ GEOMETRY_REGEXP
            ActiveRecord::ConnectionAdapters::SpatialMysqlColumn
          else
            ActiveRecord::ConnectionAdapters::MysqlColumn
          end
        columns << klass.new(field[0], field[4], field[1], field[2] == "YES")
      end

      result.free
      columns
    end

    # Check the nature of the index : If it is SPATIAL, it is indicated in the
    # IndexDefinition object (redefined to add the spatial flag in
    # spatial_adapter_common.rb)
    def indexes(table_name, name = nil)#:nodoc:
      indexes = []
      current_index = nil
      show_keys_from(table_name, name).each do |row|
        if current_index != row[2]
          next if row[2] == "PRIMARY" # skip the primary key
          current_index = row[2]
          indexes << ActiveRecord::ConnectionAdapters::IndexDefinition \
            .new(row[0], row[2], row[1] == "0", [], row[10] == "SPATIAL")
        end
        indexes.last.columns << row[4]
      end
      indexes
    end

    def options_for(table)
      engine = show_table_status_like(table).fetch_row[1]
      engine !~ /inno/i ? "ENGINE=#{engine}" : nil
    end
  end

  class SpatialMysqlColumn < MysqlColumn
    include SpatialAdapter::SpatialColumn
    extend SpatialAdapter::Base::Mysql::SpatialColumn
  end
end
