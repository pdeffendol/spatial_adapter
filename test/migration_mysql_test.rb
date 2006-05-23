$:.unshift(File.dirname(__FILE__))

require 'test/unit'
require 'common/common_mysql'

class Park < ActiveRecord::Base
end


class MigrationMysqlTest < Test::Unit::TestCase
  
  def test_creation_modification
    #creation
    #add column
    #remove column
    #add index
    #remove index
    
    connection = ActiveRecord::Base.connection

    #create a table with a geometric column
    ActiveRecord::Schema.define() do
      create_table "parks", :options => "ENGINE=MyISAM" , :force => true do |t|
        t.column "data" , :string, :limit => 100
        t.column "value", :integer
        t.column "geom", :polygon,:null=>false
      end
    end
    
    #TEST
    assert_equal(4,connection.columns("parks").length) # the 3 defined + id
    connection.columns("parks").each do |col|
      if col.name == "geom"
        assert(col.is_a?(SpatialColumn))
        assert(:polygon,col.geometry_type)
        assert(:geometry,col.type)
        assert(col.null == false)
      end
    end

    ActiveRecord::Schema.define() do
      add_column "parks","geom2", :multi_point
    end
    
    #TEST
    assert_equal(5,connection.columns("parks").length)
    connection.columns("parks").each do |col|
      if col.name == "geom2"
        assert(col.is_a?(SpatialColumn))
        assert(:multi_point,col.geometry_type)
        assert(:geometry,col.type)
        assert(col.null != false)
      end
    end
    
    ActiveRecord::Schema.define() do
      remove_column "parks","geom2"
    end

    #TEST
    assert_equal(4,connection.columns("parks").length)
    has_geom2= false
    connection.columns("parks").each do |col|
      if col.name == "geom2"
        has_geom2=true
      end
    end
    assert(!has_geom2)
    
    #TEST
    assert_equal(0,connection.indexes("parks").length) #index on id does not count
    
    ActiveRecord::Schema.define() do      
      add_index "parks","geom",:spatial=>true,:name => "example_spatial_index"
    end
    
    #TEST
    assert_equal(1,connection.indexes("parks").length)
    assert(connection.indexes("parks")[0].spatial)
    assert_equal("example_spatial_index",connection.indexes("parks")[0].name)

    ActiveRecord::Schema.define() do
      remove_index "parks",:name=> "example_spatial_index"
    end
    
    #TEST
    assert_equal(0,connection.indexes("parks").length)
    
  end

  
  def test_dump
    #Force the creation a table
    ActiveRecord::Schema.define() do
      create_table "parks", :options => "ENGINE=MyISAM" , :force => true do |t|
        t.column "data" , :string, :limit => 100
        t.column "value", :integer
        t.column "geom", :polygon,:null=>false
      end
      
      add_index "parks","geom",:spatial=>true,:name => "example_spatial_index"
    
    end

    #dump it : tables from other tests will be dumped too but not a problem
    File.open('schema.rb', "w") do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
    
    #load it again 
    load('schema.rb')
    
    File.delete('schema.rb')

    #reset
    connection = ActiveRecord::Base.connection

    columns = connection.columns("parks")
    assert(4,columns.length)
    
    connection.columns("parks").each do |col|
      if col.name == "geom"
        assert(col.is_a?(SpatialColumn))
        assert(:polygon,col.geometry_type)
        assert(:geometry,col.type)
        assert(col.null == false)
      end
    end

    assert_equal(1,connection.indexes("parks").length)
    assert(connection.indexes("parks")[0].spatial)
    assert_equal("example_spatial_index",connection.indexes("parks")[0].name)
   end

  
end
