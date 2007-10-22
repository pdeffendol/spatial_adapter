class SpatialAdapterNotCompatibleError < StandardError
end

adapter = ActiveRecord::Base.configurations[RAILS_ENV].symbolize_keys[:adapter]

if adapter == "mysql"
  require 'mysql_spatial_adapter'
elsif adapter == "postgresql"
  require 'post_gis_adapter'
else
  raise SpatialAdapterNotCompatibleError.new("Only MySQL and PostgreSQL are currently supported by the spatial adapter plugin.")
end


