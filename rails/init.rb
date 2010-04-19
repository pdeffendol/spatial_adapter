# Rails initialization
#
# This will load the adapter for the currently used database configuration, if
# it exists.

module SpatialAdapter
  class NotCompatibleError < ::StandardError
  end
end

begin
  adapter = ActiveRecord::Base.configurations[RAILS_ENV]['adapter']
  require "spatial_adapter/#{adapter}"
rescue LoadError
  raise SpatialAdapter::NotCompatibleError.new("spatial_adapter does not currently support the #{adapter} database.")
end
