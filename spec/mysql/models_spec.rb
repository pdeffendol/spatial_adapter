require 'spec_helper'
require 'shared_examples'
require 'spatial_adapter/mysql'
require 'db/mysql_raw'
require 'models/common'

describe "Spatially-enabled Models" do
  before :each do
    mysql_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe "inserting records" do
    it 'should save Point objects' do
      model = PointModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.point.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save LineString objects' do
      model = LineStringModel.new(:extra => 'test', :geom => GeometryFactory.line_string)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.line_string.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save Polygon objects' do
      model = PolygonModel.new(:extra => 'test', :geom => GeometryFactory.polygon)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.polygon.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiPoint objects' do
      model = MultiPointModel.new(:extra => 'test', :geom => GeometryFactory.multi_point)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.multi_point.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiLineString objects' do
      model = MultiLineStringModel.new(:extra => 'test', :geom => GeometryFactory.multi_line_string)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.multi_line_string.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save MultiPolygon objects' do
      model = MultiPolygonModel.new(:extra => 'test', :geom => GeometryFactory.multi_polygon)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.multi_polygon.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save GeometryCollection objects' do
      model = GeometryCollectionModel.new(:extra => 'test', :geom => GeometryFactory.geometry_collection)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.geometry_collection.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  
    it 'should save Geometry objects' do
      model = GeometryModel.new(:extra => 'test', :geom => GeometryFactory.point)
      @connection.should_receive(:insert_sql).with(Regexp.new(GeometryFactory.point.as_hex_wkb), anything(), anything(), anything(), anything())
      model.save.should == true
    end
  end

  include CommonModelActions
end

