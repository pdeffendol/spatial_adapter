module SpatialAdapter::Base::Mysql
  module Adapter
    GEOMETRY_REGEXP = /geometry|point|linestring|polygon|multipoint|multilinestring|multipolygon|geometrycollection/i

    def supports_geographic?
      false
    end

    def self.included klass
      klass.class_eval do
        def native_database_types
          (defined?(NATIVE_DATABASE_TYPES) ? NATIVE_DATABASE_TYPES : super()) \
            .merge(SpatialAdapter.geometry_data_types)
        end

        # Redefines the quote method to add behaviour for when a Geometry is
        # encountered ; used when binding variables in find_by methods
        def quote(value, column = nil)
          if value.kind_of?(GeoRuby::SimpleFeatures::Geometry)
            "GeomFromWKB(0x#{value.as_hex_wkb},#{value.srid})"
          else
            super(value,column)
          end
        end

        #Redefines add_index to support the case where the index is spatial
        #If the :spatial key in the options table is true, then the sql string for a spatial index is created
        def add_index(table_name,column_name,options = {})
          index_name = options[:name] || index_name(table_name,:column => Array(column_name))

          if options[:spatial]
            execute "CREATE SPATIAL INDEX #{index_name} ON #{table_name} (#{Array(column_name).join(", ")})"
          else
            super
          end
        end
      end
    end

    private

    def show_table_status_like(table)
      execute("SHOW TABLE STATUS LIKE '#{table}'")
    end

    def show_fields_from(table, name = nil)
      execute("SHOW FIELDS FROM #{quote_table_name(table)}", name)
    end

    def show_keys_from(table, name = nil)
      execute("SHOW KEYS FROM #{quote_table_name(table)}", name) || []
    end
  end
end
