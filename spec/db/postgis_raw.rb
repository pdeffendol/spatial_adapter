postgis_connection

ActiveRecord::Schema.define() do
  execute <<-SQL
    drop table if exists point_models;
    create table point_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('point_models', 'geom', 4326, 'POINT', 2);

    drop table if exists line_string_models;
    create table line_string_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('line_string_models', 'geom', 4326, 'LINESTRING', 2);

    drop table if exists polygon_models;
    create table polygon_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('polygon_models', 'geom', 4326, 'POLYGON', 2);

    drop table if exists multi_point_models;
    create table multi_point_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('multi_point_models', 'geom', 4326, 'MULTIPOINT', 2);

    drop table if exists multi_line_string_models;
    create table multi_line_string_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('multi_line_string_models', 'geom', 4326, 'MULTILINESTRING', 2);

    drop table if exists multi_polygon_models;
    create table multi_polygon_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('multi_polygon_models', 'geom', 4326, 'MULTIPOLYGON', 2);

    drop table if exists geometry_collection_models;
    create table geometry_collection_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('geometry_collection_models', 'geom', 4326, 'GEOMETRYCOLLECTION', 2);

    drop table if exists geometry_models;
    create table geometry_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('geometry_models', 'geom', 4326, 'GEOMETRY', 2);
    
    drop table if exists pointz_models;
    create table pointz_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('pointz_models', 'geom', 4326, 'POINT', 3);
    
    drop table if exists pointm_models;
    create table pointm_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('pointm_models', 'geom', 4326, 'POINTM', 3);

    drop table if exists point4_models;
    create table point4_models
    (
    	id serial primary key,
    	extra varchar(255)
    );
    select AddGeometryColumn('point4_models', 'geom', 4326, 'POINT', 4);
  SQL
end
