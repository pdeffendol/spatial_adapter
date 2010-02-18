require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLTableDefinition < TableDefinition
      attr_reader :geom_columns
      
      def column(name, type, options = {})
        unless (@base.geometry_data_types[type.to_sym].nil? or
                (options[:create_using_addgeometrycolumn] == false))

          geom_column = PostgreSQLColumnDefinition.new(@base, name, type)
          geom_column.null = options[:null]
          geom_column.srid = options[:srid] || -1
          geom_column.with_z = options[:with_z] || false 
          geom_column.with_m = options[:with_m] || false
         
          @geom_columns ||= []
          @geom_columns << geom_column          
        else
          super(name, type, options)
        end
      end    
    end

    class PostgreSQLColumnDefinition < ColumnDefinition
      attr_accessor :srid, :with_z, :with_m
      attr_reader :spatial

      def initialize(base = nil, name = nil, type=nil, limit=nil, default=nil, null=nil, srid=-1, with_z=false, with_m=false)
        super(base, name, type, limit, default,null)
        @spatial = true
        @srid = srid
        @with_z = with_z
        @with_m = with_m
      end
      
      def to_sql(table_name)
        if @spatial
          type_sql = type_to_sql(type.to_sym)
          type_sql += "M" if with_m and !with_z
          if with_m and with_z
            dimension = 4 
          elsif with_m or with_z
            dimension = 3
          else
            dimension = 2
          end
          
          column_sql = "SELECT AddGeometryColumn('#{table_name}','#{name}',#{srid},'#{type_sql}',#{dimension})"
          column_sql += ";ALTER TABLE #{table_name} ALTER #{name} SET NOT NULL" if null == false
          column_sql
        else
          super
        end
      end
  
      private
      
      def type_to_sql(name, limit=nil)
        base.type_to_sql(name, limit) rescue name
      end   
    end
  end
end
