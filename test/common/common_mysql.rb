$:.unshift(File.dirname(__FILE__) + '/../../lib')

require 'active_record'

ActiveRecord::Base.establish_connection(YAML.load_file(File.dirname(__FILE__) +  '/../db/database_mysql.yml'))

require File.dirname(__FILE__) + '/../../init.rb'





                                      




