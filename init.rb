class SpatialAdapterNotCompatibleError < StandardError
end


if defined?(RAILS_ENV)
  adapter = ActiveRecord::Base.configurations[RAILS_ENV].symbolize_keys[:adapter]
else
  if ActiveRecord::Base.connection.is_a?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
   adapter = "mysql"
  else
     adapter = "postgresql"
  end
end

if adapter == "mysql"
  require 'mysql_spatial_adapter'
elsif adapter == "postgresql"
  require 'post_gis_adapter'
else
  raise SpatialAdapterNotCompatibleError.new("Only MySQL and PostgreSQL are currently supported by the spatial adapter plugin.")
end


