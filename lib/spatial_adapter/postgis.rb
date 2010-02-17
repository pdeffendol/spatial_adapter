require 'active_record/connection_adapters/postgresql_adapter'

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
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
  
  def geometry_data_types
    {
      :point => { :name => "POINT" },
      :line_string => { :name => "LINESTRING" },
      :polygon => { :name => "POLYGON" },
      :geometry_collection => { :name => "GEOMETRYCOLLECTION" },
      :multi_point => { :name => "MULTIPOINT" },
      :multi_line_string => { :name => "MULTILINESTRING" },
      :multi_polygon => { :name => "MULTIPOLYGON" },
      :geometry => { :name => "GEOMETRY"},
      :geography => {:name => 'geography'}
    }
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
    SELECT i.relname, d.indisunique, d.indkey, t.oid, am.amname
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

  private
  
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
    class SpatialPostgreSQLColumn < PostgreSQLColumn
      attr_reader  :spatial, :geometry_type, :srid, :with_z, :with_m

      def initialize(name, default, sql_type = nil, null = true,srid=-1,with_z=false,with_m=false)
        super(name, default, sql_type, null)
        @geometry_type = geometry_simplified_type(@sql_type)
        @srid = srid
        @with_z = with_z
        @with_m = with_m
      end
      
      # Redefines type_cast to add support for geometries
      # alias_method :type_cast_without_spatial, :type_cast
      def type_cast(value)
        return nil if value.nil?
        case type
        when :geometry then self.class.string_to_geometry(value)
        else super
        end
      end

      #Redefines type_cast_code to add support for geometries. 
      #
      #WARNING : Since ActiveRecord keeps only the string values directly returned from the database, it translates from these to the correct types everytime an attribute is read (using the code returned by this method), which is probably ok for simple types, but might be less than efficient for geometries. Also you cannot modify the geometry object returned directly or your change will not be saved. 
      # alias_method :type_cast_code_without_spatial, :type_cast_code
      def type_cast_code(var_name)
        case type
        when :geometry then "#{self.class.name}.string_to_geometry(#{var_name})"
        else super
        end
      end


      #Redefines klass to add support for geometries
      # alias_method :klass_without_spatial, :klass
      def klass
        case type
        when :geometry then GeoRuby::SimpleFeatures::Geometry
        else super
        end
      end

      private

      #Redefines the simplified_type method to add behabiour for when a column is of type geometry
      def simplified_type(field_type)
        case field_type
        when /geometry|point|linestring|polygon|multipoint|multilinestring|multipolygon|geometrycollection/i then :geometry
        else super
        end
      end

      #less simlpified geometric type to be use in migrations
      def geometry_simplified_type(field_type)
        case field_type
        when /^point$/i then :point
        when /^linestring$/i then :line_string
        when /^polygon$/i then :polygon
        when /^geometry$/i then :geometry
        when /multipoint/i then :multi_point
        when /multilinestring/i then :multi_line_string
        when /multipolygon/i then :multi_polygon
        when /geometrycollection/i then :geometry_collection
        end
      end

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
