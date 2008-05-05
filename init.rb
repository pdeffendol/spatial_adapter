class SpatialAdapterNotCompatibleError < StandardError
end


case ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
when 'mysql'
  require 'mysql_spatial_adapter'
when 'postgresql'
  require 'post_gis_adapter'
else
  raise SpatialAdapterNotCompatibleError.new("Only MySQL and PostgreSQL are currently supported by the spatial adapter plugin.")
end


