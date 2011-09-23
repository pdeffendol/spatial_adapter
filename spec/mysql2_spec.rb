require 'spec_helper'
require 'shared/mysql_connection_adapter_spec'
require 'shared/mysql_migration_spec'
require 'shared/mysql_schema_dumper_spec'
require 'shared/mysql_models_spec'
require 'shared/common_model_actions_spec'
require 'spatial_adapter/mysql2'
require 'db/mysql2_raw'
require 'models/common'

describe ActiveRecord::ConnectionAdapters::Mysql2Adapter do
  it_should_behave_like 'common model actions'
  it_should_behave_like 'a modified mysql adapter' do
    let(:establish){ mysql2_connection }
    let(:column) do
      ActiveRecord::ConnectionAdapters::Mysql2Column
    end
    let(:spatial_column) do
      ActiveRecord::ConnectionAdapters::SpatialMysql2Column
    end
  end
  it_should_behave_like 'spatially enabled migrations' do
    let(:establish){ mysql2_connection }
  end
  it_should_behave_like 'spatially enabled schema dump' do
    let(:establish){ mysql2_connection }
  end
  it_should_behave_like 'spatially enabled models' do
    let(:establish){ mysql2_connection }
  end
end
