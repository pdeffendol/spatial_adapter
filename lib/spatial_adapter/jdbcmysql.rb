require 'spatial_adapter'
require 'spatial_adapter/base/mysql'
require 'active_record/connection_adapters/jdbcmysql_adapter'

module ActiveRecord::ConnectionAdapters
  class MysqlAdapter
    include SpatialAdapter::Base::Mysql::Adapter

    #Redefinition of columns to add the information that a column is geometric
    def columns(table_name, name = nil)#:nodoc:
      show_fields_from(table_name, name).map do |field|
        klass = \
          if field["Type"] =~ GEOMETRY_REGEXP
            ActiveRecord::ConnectionAdapters::SpatialMysqlColumn
          else
            ActiveRecord::ConnectionAdapters::MysqlColumn
          end
        klass.new(field['Field'], field['Default'], field['Type'], field['Null'] == "YES")
      end
    end

    # Check the nature of the index : If it is SPATIAL, it is indicated in the
    # IndexDefinition object (redefined to add the spatial flag in
    # spatial_adapter_common.rb)
    def indexes(table_name, name = nil)#:nodoc:
      indexes = []
      current_index = nil
      show_keys_from(table_name, name).each do |row|
        if current_index != row['Key_name']
          next if row['Key_name'] == "PRIMARY" # skip the primary key
          current_index = row['Key_name']
          indexes << ActiveRecord::ConnectionAdapters::IndexDefinition \
            .new(row['Table'], row['Key_name'], row['Non_unique'] == "0", [], row['Index_type'] == "SPATIAL")
        end
        indexes.last.columns << row['Column_name']
      end
      indexes
    end

    def options_for(table)
      engine = show_table_status_like(table).first['Engine']
      engine !~ /inno/i ? "ENGINE=#{engine}" : nil
    end
  end

  class SpatialMysqlColumn < MysqlColumn
    include SpatialAdapter::SpatialColumn
    extend SpatialAdapter::Base::Mysql::SpatialColumn
  end
end
