shared_examples_for 'spatially enabled schema dump' do
  let(:establish){ mysql_connection }

  let(:connection) do
    establish
    ActiveRecord::Base.connection
  end

  before :all do
    ActiveRecord::Schema.define do
      create_table :migrated_geometry_models, :options=> "ENGINE=MyISAM", :force => true do |t|
        t.integer :extra
        t.point   :geom, :null => false
      end
      add_index :migrated_geometry_models, :geom, :spatial => true,
        :name => 'test_spatial_index'
    end

    File.open('schema.rb', "w:UTF-8") do |file|
      ActiveRecord::SchemaDumper.dump(connection, file)
    end

    connection.drop_table "migrated_geometry_models"

    load('schema.rb')
  end

  after :all do
    File.delete('schema.rb')

    connection.drop_table "migrated_geometry_models"
  end

  it "should preserve spatial attributes of tables" do
    columns = connection.columns("migrated_geometry_models")

    columns.should have(3).items
    geom_column = columns.select{|c| c.name == 'geom'}.first
    geom_column.should be_a(SpatialAdapter::SpatialColumn)
    geom_column.geometry_type.should == :point
    geom_column.type.should == :string
  end

  it "should preserve spatial indexes" do
    indexes = connection.indexes("migrated_geometry_models")

    indexes.should have(1).item

    indexes.first.name.should == 'test_spatial_index'
    indexes.first.columns.should == ["geom"]
    indexes.first.spatial.should == true
  end
end
