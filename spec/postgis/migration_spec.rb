require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class MigratedGeometryModel < ActiveRecord::Base
end

describe "Spatially-enabled Migrations" do
  before :each do
    postgis_connection
    @connection = ActiveRecord::Base.connection
  end
  
  describe "creating tables" do
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end
    
    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should create #{type.to_s} columns" do
        ActiveRecord::Schema.define do
          create_table :migrated_geometry_models, :force => true do |t|
            t.integer :extra
            t.send(type, :geom)
          end
        end

        geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
        geom_column.should be_a(SpatialAdapter::SpatialColumn)
        geom_column.geometry_type.should == type
        geom_column.type.should == :geometry
        geom_column.with_z.should == false
        geom_column.with_m.should == false
        geom_column.srid.should == -1
      end
    end
    
      it "should create #{type.to_s} geography columns" do
        ActiveRecord::Schema.define do
          create_table :migrated_geometry_models, :force => true do |t|
            t.integer :extra
            t.send(type, :geom, :geography => true)
          end
        end

        geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
        geom_column.should be_a(SpatialAdapter::SpatialColumn)
        geom_column.geometry_type.should == type
        geom_column.type.should == :geography
        geom_column.with_z.should == false
        geom_column.with_m.should == false
        geom_column.srid.should == -1
      end
    end
    
    it "should create 3d (xyz) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_z => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.with_z.should == true
      geom_column.with_m.should == false
      geom_column.srid.should == -1
    end
    
    
    it "should create 3d (xym) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_m => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :point
      geom_column.type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
    
    
    it "should create 4d (xyzm) geometry columns" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.point   :geom, :with_z => true, :with_m => true
        end
      end
      
      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :point
      geom_column.type.should == :geometry
      geom_column.with_z.should == true
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end
    

    it "should create GEOMETRY columns with specified SRID" do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
          t.geometry :geom, :srid => 4326
        end
      end

      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :geometry
      geom_column.type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == false
      geom_column.srid.should == 4326
    end
  end

  describe "adding columns" do
    before :each do
      ActiveRecord::Schema.define do
        create_table :migrated_geometry_models, :force => true do |t|
          t.integer :extra
        end
      end
    end
    
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end

    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should add #{type.to_s} columns" do
        ActiveRecord::Schema.define do
          add_column :migrated_geometry_models, :geom, type
        end

        geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
        geom_column.should be_a(SpatialAdapter::SpatialColumn)
        geom_column.geometry_type.should == type
        geom_column.type.should == :geometry
        geom_column.with_z.should == false
        geom_column.with_m.should == false
        geom_column.srid.should == -1
      end
    end

    it "should add 3d (xyz) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_z => true
      end

      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.with_z.should == true
      geom_column.with_m.should == false
      geom_column.srid.should == -1
    end


    it "should add 3d (xym) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_m => true
      end

      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :point
      geom_column.type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end


    it "should add 4d (xyzm) geometry columns" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :point, :with_z => true, :with_m => true
      end

      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :point
      geom_column.type.should == :geometry
      geom_column.with_z.should == true
      geom_column.with_m.should == true
      geom_column.srid.should == -1
    end

    it "should add GEOMETRY columns with specified SRID" do
      ActiveRecord::Schema.define do
        add_column :migrated_geometry_models, :geom, :geometry, :srid => 4326
      end

      geom_column = @connection.columns(:migrated_geometry_models).select{|c| c.name == 'geom'}.first
      geom_column.should be_a(SpatialAdapter::SpatialColumn)
      geom_column.geometry_type.should == :geometry
      geom_column.type.should == :geometry
      geom_column.with_z.should == false
      geom_column.with_m.should == false
      geom_column.srid.should == 4326
    end
  end
  
  describe "removing columns" do
    before :each do
    end
    
    after :each do
      @connection.drop_table "migrated_geometry_models"
    end

    SpatialAdapter.geometry_data_types.keys.each do |type|
      it "should remove #{type.to_s} columns using DropGeometryColumn" do
        ActiveRecord::Schema.define do
          create_table :migrated_geometry_models, :force => true do |t|
            t.integer :extra
            t.send(type, :geom)
          end
        end

        @connection.should_receive(:execute).with(/DropGeometryColumn(.*migrated_geometry_models.*geom)/)
        ActiveRecord::Schema.define do
          remove_column :migrated_geometry_models, :geom
        end
        @connection.should_receive(:execute).with(anything())
      end
    end
  end
  
end