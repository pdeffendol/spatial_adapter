require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  describe '#postgis_version' do
    it 'should report a version number if PostGIS is installed' do
      postgis_connection
      ActiveRecord::Base.connection.postgis_version.should_not be_nil
    end
    
    it 'should report nil if PostGIS is not installed' do
      postgis_connection
      ActiveRecord::Base.connection.create_database 'spatial_adapter_disabled'
      ActiveRecord::Base.establish_connection(
        :adapter => 'postgresql',
        :database => 'spatial_adapter_disabled'
      )
      ActiveRecord::Base.connection.postgis_version.should be_nil
      postgis_connection
      ActiveRecord::Base.connection.drop_database 'spatial_adapter_disabled'
    end
  end
  
  describe '#postgis_major_version' do
    it 'should be the first component of the version number' do
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return('1.5.0')
      ActiveRecord::Base.connection.postgis_major_version.should == 1
    end
    
    it 'should be nil if PostGIS is not installed' do
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return(nil)
      ActiveRecord::Base.connection.postgis_major_version.should be_nil
    end
  end
  
  describe '#postgis_minor_version' do
    it 'should be the second component of the version number' do
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return('1.5.0')
      ActiveRecord::Base.connection.postgis_minor_version.should == 5
    end
    
    it 'should be nil if PostGIS is not installed' do
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return(nil)
      ActiveRecord::Base.connection.postgis_minor_version.should be_nil
    end
  end
  
  describe '#spatial?' do
    it 'should be true if PostGIS is installed' do
      postgis_connection
      ActiveRecord::Base.connection.should be_spatial
    end
    
    it 'should be false if PostGIS is not installed' do
      postgis_connection
      ActiveRecord::Base.connection.create_database 'spatial_adapter_disabled'
      ActiveRecord::Base.establish_connection(
        :adapter => 'postgresql',
        :database => 'spatial_adapter_disabled'
      )
      ActiveRecord::Base.connection.should_not be_spatial
      postgis_connection
      ActiveRecord::Base.connection.drop_database 'spatial_adapter_disabled'
    end
  end
  
  describe '#supports_geography?' do
    it "should be true for PostGIS version 1.5.0" do
      postgis_connection
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return('1.5.0')
      ActiveRecord::Base.connection.supports_geography?.should == true
    end
    
    it "should be true for PostGIS newer than 1.5.0" do
      postgis_connection
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return('1.5.1')
      ActiveRecord::Base.connection.supports_geography?.should == true
    end
    
    it "should be true for PostGIS older than 1.5.0" do
      postgis_connection
      ActiveRecord::Base.connection.stub!(:postgis_version).and_return('1.4.0')
      ActiveRecord::Base.connection.supports_geography?.should == false
    end
  end
end