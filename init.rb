class SpatialAdapterNotCompatibleError < StandardError
end

if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
  require 'mysql_spatial_adapter'
elsif ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  require 'post_gis_adapter'
else
  raise SpatialAdapterNotCompatibleError.new("Only MySQL and PostgreSQL are currently supported by the spatial adapter plugin.")
end
