require 'active_record/connection_adapters/postgresql_adapter'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
  include SpatialAdapter
  
  def postgis_version
    begin
      select_value("SELECT postgis_full_version()").scan(/POSTGIS="([\d\.]*)"/)[0][0]
    rescue ActiveRecord::StatementInvalid
      nil
    end
  end
  
  def postgis_major_version
    version = postgis_version
    version ? version.scan(/^(\d)\.\d\.\d$/)[0][0].to_i : nil
  end
  
  def postgis_minor_version
    version = postgis_version
    version ? version.scan(/^\d\.(\d)\.\d$/)[0][0].to_i : nil
  end
  
  def spatial?
    !postgis_version.nil?
  end
  
  def supports_geography?
    postgis_major_version > 1 || (postgis_major_version == 1 && postgis_minor_version >= 5)
  end
  
  alias :original_native_database_types :native_database_types
  def native_database_types
    original_native_database_types.merge!(geometry_data_types)
  end

  alias :original_quote :quote
  #Redefines the quote method to add behaviour for when a Geometry is encountered
  def quote(value, column = nil)
    if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
      "'#{value.as_hex_ewkb}'"
    else
      original_quote(value,column)
    end
  end

  def columns(table_name, name = nil) #:nodoc:
    raw_geom_infos = column_spatial_info(table_name)
    
    column_definitions(table_name).collect do |name, type, default, notnull|
      case type
      when /geometry/i
        raw_geom_info = raw_geom_infos[name]
        if raw_geom_info.nil?
          ActiveRecord::ConnectionAdapters::SpatialPostgreSQLColumn.create_simplified(name, default, notnull == "f")
        else
          ActiveRecord::ConnectionAdapters::SpatialPostgreSQLColumn.new(name, default, raw_geom_info.type, notnull == "f", raw_geom_info.srid, raw_geom_info.with_z, raw_geom_info.with_m)
        end
      else
        ActiveRecord::ConnectionAdapters::PostgreSQLColumn.new(name, default, type, notnull == "f")
      end
    end
  end

  def create_table(table_name, options = {})
    # Using the subclassed table definition
    table_definition = ActiveRecord::ConnectionAdapters::PostgreSQLTableDefinition.new(self)
    table_definition.primary_key(options[:primary_key] || ActiveRecord::Base.get_primary_key(table_name.to_s.singularize)) unless options[:id] == false

    yield table_definition if block_given?

    if options[:force] && table_exists?(table_name)
      drop_table(table_name, options)
    end

    create_sql = "CREATE#{' TEMPORARY' if options[:temporary]} TABLE "
    create_sql << "#{quote_table_name(table_name)} ("
    create_sql << table_definition.to_sql
    create_sql << ") #{options[:options]}"
    execute create_sql

    # This is the additional portion for PostGIS
    unless table_definition.geom_columns.nil?
      table_definition.geom_columns.each do |geom_column|
        execute geom_column.to_sql(table_name)
      end
    end
  end

  alias :original_remove_column :remove_column
  def remove_column(table_name, column_name, options = {})
    columns(table_name).each do |col|
      if col.name == column_name.to_s 
        #check if the column is geometric
        unless geometry_data_types[col.type].nil? or
               (options[:remove_using_dropgeometrycolumn] == false)
          execute "SELECT DropGeometryColumn('#{table_name}','#{column_name}')"
        else
          original_remove_column(table_name, column_name)
        end
      end
    end
  end
  
  alias :original_add_column :add_column
  def add_column(table_name, column_name, type, options = {})
    unless geometry_data_types[type].nil? or (options[:create_using_addgeometrycolumn] == false)
      geom_column = ActiveRecord::ConnectionAdapters::PostgreSQLColumnDefinition.new(self, column_name, type, nil, nil, options[:null], options[:srid] || -1 , options[:with_z] || false , options[:with_m] || false)
      execute geom_column.to_sql(table_name)
    else
      original_add_column(table_name, column_name, type, options)
    end
  end

  # Adds an index to a column.
  def add_index(table_name, column_name, options = {})
    column_names = Array(column_name)
    index_name   = index_name(table_name, :column => column_names)

    if Hash === options # legacy support, since this param was a string
      index_type = options[:unique] ? "UNIQUE" : ""
      index_name = options[:name] || index_name
      index_method = options[:spatial] ? 'USING GIST' : ""
    else
      index_type = options
    end
    quoted_column_names = column_names.map { |e| quote_column_name(e) }.join(", ")
    execute "CREATE #{index_type} INDEX #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_method} (#{quoted_column_names})"
  end

  # Returns the list of all indexes for a table.
  # This is a full replacement for the ActiveRecord method and as a result
  # has a higher probability of breaking in future releases
  def indexes(table_name, name = nil)
    schemas = schema_search_path.split(/,/).map { |p| quote(p) }.join(',')
    result = query(<<-SQL, name)
    SELECT distinct i.relname, d.indisunique, d.indkey, t.oid, am.amname
      FROM pg_class t, pg_class i, pg_index d, pg_attribute a, pg_am am
    WHERE i.relkind = 'i'
      AND d.indexrelid = i.oid
      AND d.indisprimary = 'f'
      AND t.oid = d.indrelid
      AND i.relam = am.oid
      AND t.relname = '#{table_name}'
      AND a.attrelid = t.oid
      AND ( d.indkey[0]=a.attnum OR d.indkey[1]=a.attnum
        OR d.indkey[2]=a.attnum OR d.indkey[3]=a.attnum
        OR d.indkey[4]=a.attnum OR d.indkey[5]=a.attnum
        OR d.indkey[6]=a.attnum OR d.indkey[7]=a.attnum
        OR d.indkey[8]=a.attnum OR d.indkey[9]=a.attnum )
    ORDER BY i.relname
    SQL

    indexes = []

    indexes = result.map do |row|
      index_name = row[0]
      unique = row[1] == 't'
      indkey = row[2].split(" ")
      oid = row[3]
      spatial = row[4] == "gist"

      columns = query(<<-SQL, "Columns for index #{row[0]} on #{table_name}").inject({}) {|attlist, r| attlist[r[1]] = r[0]; attlist}
      SELECT a.attname, a.attnum
      FROM pg_attribute a
      WHERE a.attrelid = #{oid}
      AND a.attnum IN (#{indkey.join(",")})
      SQL

      column_names = indkey.map {|attnum| columns[attnum] }
      ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, index_name, unique, column_names, spatial)
    end

    indexes
  end

  def disable_referential_integrity(&block) #:nodoc:
    if supports_disable_referential_integrity?() then
      execute(tables_without_postgis.collect { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER ALL" }.join(";"))
    end
    yield
  ensure
    if supports_disable_referential_integrity?() then
      execute(tables_without_postgis.collect { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER ALL" }.join(";"))
    end
  end

  private
  
  def tables_without_postgis
    tables - %w{ geometry_columns spatial_ref_sys }
  end
  
  def column_spatial_info(table_name)
    constr = query("SELECT * FROM geometry_columns WHERE f_table_name = '#{table_name}'")

    raw_geom_infos = {}
    constr.each do |constr_def_a|
      raw_geom_infos[constr_def_a[3]] ||= SpatialAdapter::RawGeomInfo.new
      raw_geom_infos[constr_def_a[3]].type = constr_def_a[6]
      raw_geom_infos[constr_def_a[3]].dimension = constr_def_a[4].to_i
      raw_geom_infos[constr_def_a[3]].srid = constr_def_a[5].to_i

      if raw_geom_infos[constr_def_a[3]].type[-1] == ?M
        raw_geom_infos[constr_def_a[3]].with_m = true
        raw_geom_infos[constr_def_a[3]].type.chop!
      else
        raw_geom_infos[constr_def_a[3]].with_m = false
      end
    end

    raw_geom_infos.each_value do |raw_geom_info|
      #check the presence of z and m
      raw_geom_info.convert!
    end

    raw_geom_infos

  end
end

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
