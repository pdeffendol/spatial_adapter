require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'db/postgis_raw'
require 'models/common'

describe "Modified PostgreSQLAdapter" do
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

  describe "#columns" do
    describe "type" do
      it "should be SpatialPostgreSQLColumn if column is a spatial data type" do
        PointModel.columns.select{|c| c.name == 'geom'}.first.should be_a(ActiveRecord::ConnectionAdapters::SpatialPostgreSQLColumn)
      end
      
      it "should be PostgreSQLColumn if column is not a spatial data type" do
        PointModel.columns.select{|c| c.name == 'extra'}.first.should be_a(ActiveRecord::ConnectionAdapters::PostgreSQLColumn)
      end
    end
    
    describe "@geometry_type" do
      it "should be :point for columns restricted to POINT types" do
        PointModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :point
      end
      
      it "should be :line_string for columns restricted to LINESTRING types" do
        LineStringModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :line_string
      end

      it "should be :polygon for columns restricted to POLYGON types" do
        PolygonModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :polygon
      end

      it "should be :multi_point for columns restricted to MULTIPOINT types" do
        MultiPointModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_point
      end

      it "should be :multi_line_string for columns restricted to MULTILINESTRING types" do
        MultiLineStringModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_line_string
      end
      
      it "should be :multi_polygon for columns restricted to MULTIPOLYGON types" do
        MultiPolygonModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :multi_polygon
      end
      
      it "should be :geometry_collection for columns restricted to GEOMETRYCOLLECTION types" do
        GeometryCollectionModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :geometry_collection
      end
      
      it "should be :geometry for columns not restricted to a type" do
        GeometryModel.columns.select{|c| c.name == 'geom'}.first.geometry_type.should == :geometry
      end
    end
  end
  
  describe "#indexes" do
    before :each do
      @indexes = @connection.indexes('point_models', 'index_point_models_on_geom')
    end
    
    it "should be marked as spatial if a GIST index" do
      @indexes.select{|i| i.columns.include?('geom')}.first.spatial.should == true
    end
    
    it "should not be marked as spatial if not a GIST index" do
      @indexes.select{|i| i.columns.include?('extra')}.first.spatial.should == false
    end
  end  
  
  describe "#add_index" do
    after :each do
      @connection.should_receive(:execute).with(any_args())
      @connection.remove_index('geometry_models', 'geom')
    end
    
    it "should create a spatial index given :spatial => true" do
      @connection.should_receive(:execute).with(/using gist/i)
      @connection.add_index('geometry_models', 'geom', :spatial => true)
    end
    
    it "should not create a spatial index unless specified" do
      @connection.should_not_receive(:execute).with(/using gist/i)
      @connection.add_index('geometry_models', 'extra')
    end
  end
end