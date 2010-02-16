require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  before :each do
    postgis_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe '#postgis_version' do
    it 'should report a version number if PostGIS is installed' do
      @connection.should_receive(:select_value).with('SELECT postgis_full_version()').and_return('POSTGIS="1.5.0" GEOS="3.2.0-CAPI-1.6.0" PROJ="Rel. 4.7.1, 23 September 2009" LIBXML="2.7.6" USE_STATS')
      @connection.postgis_version.should_not be_nil
    end
    
    it 'should report nil if PostGIS is not installed' do
      @connection.should_receive(:select_value).with('SELECT postgis_full_version()').and_raise(ActiveRecord::StatementInvalid)
      @connection.postgis_version.should be_nil
    end
  end
  
  describe '#postgis_major_version' do
    it 'should be the first component of the version number' do
      @connection.stub!(:postgis_version).and_return('1.5.0')
      @connection.postgis_major_version.should == 1
    end
    
    it 'should be nil if PostGIS is not installed' do
      @connection.stub!(:postgis_version).and_return(nil)
      @connection.postgis_major_version.should be_nil
    end
  end
  
  describe '#postgis_minor_version' do
    it 'should be the second component of the version number' do
      @connection.stub!(:postgis_version).and_return('1.5.0')
      @connection.postgis_minor_version.should == 5
    end
    
    it 'should be nil if PostGIS is not installed' do
      @connection.stub!(:postgis_version).and_return(nil)
      @connection.postgis_minor_version.should be_nil
    end
  end
  
  describe '#spatial?' do
    it 'should be true if PostGIS is installed' do
      @connection.should_receive(:select_value).with('SELECT postgis_full_version()').and_return('POSTGIS="1.5.0" GEOS="3.2.0-CAPI-1.6.0" PROJ="Rel. 4.7.1, 23 September 2009" LIBXML="2.7.6" USE_STATS')
      @connection.should be_spatial
    end
    
    it 'should be false if PostGIS is not installed' do
      @connection.should_receive(:select_value).with('SELECT postgis_full_version()').and_raise(ActiveRecord::StatementInvalid)
      @connection.should_not be_spatial
    end
  end
  
  describe '#supports_geography?' do
    it "should be true for PostGIS version 1.5.0" do
      @connection.stub!(:postgis_version).and_return('1.5.0')
      @connection.supports_geography?.should == true
    end
    
    it "should be true for PostGIS newer than 1.5.0" do
      @connection.stub!(:postgis_version).and_return('1.5.1')
      @connection.supports_geography?.should == true
    end
    
    it "should be true for PostGIS older than 1.5.0" do
      @connection.stub!(:postgis_version).and_return('1.4.0')
      @connection.supports_geography?.should == false
    end
  end
end