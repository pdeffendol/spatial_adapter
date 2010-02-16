require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'db/postgis_raw'
require 'models/postgis'

describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  before :each do
    postgis_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe "inserting records" do
    it 'should save Point objects' do
      model = PointModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.point.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save LineString objects' do
      model = LineStringModel.new(:extra => 'test', :geom => GeometryFactory.line_string)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.line_string.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save Polygon objects' do
      model = PolygonModel.new(:extra => 'test', :geom => GeometryFactory.polygon)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.polygon.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiPoint objects' do
      model = MultiPolygonModel.new(:extra => 'test', :geom => GeometryFactory.multi_point)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.multi_point.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiLineString objects' do
      model = MultiLineStringModel.new(:extra => 'test', :geom => GeometryFactory.multi_line_string)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.multi_line_string.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiPolygon objects' do
      model = MultiPolygonModel.new(:extra => 'test', :geom => GeometryFactory.multi_polygon)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.multi_polygon.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save GeometryCollection objects' do
      model = GeometryCollectionModel.new(:extra => 'test', :geom => GeometryFactory.geometry_collection)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.geometry_collection.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save Geometry objects' do
      model = GeometryModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.point.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save 3D Point (with Z coord) objects' do
      model = PointzModel.new(:extra => 'test', :geom => GeometryFactory.pointz)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.pointz.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save 3D Point (with M coord) objects' do
      model = PointmModel.new(:extra => 'test', :geom => GeometryFactory.pointm)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.pointm.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save 4D Point objects' do
      model = Point4Model.new(:extra => 'test', :geom => GeometryFactory.point4)
      @connection.should_receive(:insert).with(Regexp.new(GeometryFactory.point4.as_hex_ewkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  end
end

