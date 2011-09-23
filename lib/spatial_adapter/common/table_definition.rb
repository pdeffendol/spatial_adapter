require 'spatial_adapter'

class ActiveRecord::ConnectionAdapters::TableDefinition
  SpatialAdapter.geometry_data_types.keys.each do |column_name|
    define_method(column_name) do |*args|
      options = args.extract_options!
      args.each do |name|
        column(name, column_name, options)
      end
    end
  end
end
