shared_examples_for 'a modified mysql adapter' do
  let(:establish){ mysql_connection }
  let(:column){ ActiveRecord::ConnectionAdapters::MysqlColumn }
  let(:spatial_column){ ActiveRecord::ConnectionAdapters::SpatialMysqlColumn }

  let(:connection) do
    establish
    ActiveRecord::Base.connection
  end

  context '#supports_geographic?' do
    it "should be false" do
      connection.supports_geographic?.should == false
    end
  end

  context "#columns" do
    context "type" do
      it "should be SpatialMysqlColumn if column is a spatial data type" do
        PointModel.columns.select{|c| c.name == 'geom'} \
         .first.should be_a(spatial_column)
      end

      it "should be SpatialMysqlColumn if column is not a spatial data type" do
        PointModel.columns.select{|c| c.name == 'extra'} \
          .first.should be_a(column)
      end
    end

    describe "@geometry_type" do
      it "should be :point for columns restricted to POINT types" do
        PointModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :point
      end

      it "should be :line_string for columns restricted to LINESTRING types" do
        LineStringModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :line_string
      end

      it "should be :polygon for columns restricted to POLYGON types" do
        PolygonModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :polygon
      end

      it "should be :multi_point for columns restricted to MULTIPOINT types" do
        MultiPointModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :multi_point
      end

      it "should be :multi_line_string for columns restricted to MULTILINESTRING types" do
        MultiLineStringModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :multi_line_string
      end

      it "should be :multi_polygon for columns restricted to MULTIPOLYGON types" do
        MultiPolygonModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :multi_polygon
      end

      it "should be :geometry_collection for columns restricted to GEOMETRYCOLLECTION types" do
        GeometryCollectionModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :geometry_collection
      end

      it "should be :geometry for columns not restricted to a type" do
        GeometryModel.columns.select{|c| c.name == 'geom'} \
          .first.geometry_type.should == :geometry
      end
    end
  end

  context "#indexes" do
    let(:indexes){ connection.indexes('point_models') }

    it "should return an IndexDefinition for each index on the table" do
      indexes.should have(2).items
      indexes.each do |i|
        i.should be_a(ActiveRecord::ConnectionAdapters::IndexDefinition)
      end
    end

    it "should indicate the correct columns in the index" do
      indexes.select{|i| i.name == 'index_point_models_on_geom'} \
        .first.columns.should == ['geom']
      indexes.select{|i| i.name == 'index_point_models_on_extra'} \
        .first.columns.should == ['extra', 'more_extra']
    end

    it "should be marked as spatial if a spatial index" do
      indexes.select{|i| i.columns.include?('geom')}.first.spatial.should == true
    end

    it "should not be marked as spatial if not a spatial index" do
      indexes.select{|i| i.columns.include?('extra')}.first.spatial.should == false
    end
  end

  context "#add_index" do
    it "should create a spatial index given :spatial => true" do
      connection.should_receive(:execute).with(/create spatial index/i)
      connection.add_index('geometry_models', 'geom', :spatial => true)
    end

    it "should not create a spatial index unless specified" do
      connection.should_not_receive(:execute).with(/create spatial index/i)
      connection.add_index('geometry_models', 'extra')
    end
  end
end
