
#require 'sqlite3'

require "rubygems"
require_gem "sqlite3-ruby"


db = SQLite3::Database.new( "test.db" )
db.execute( "create table test ( foo int, bar text, baz int );" )
db.execute( "insert into test ( foo, bar, baz ) values ( 1, 'test', 3 );" )
puts "EXECUTE ----------------------------------------"
db.execute( "select * from test" ) { |row| puts row.join( ',' ) }
puts "EXECUTE2 ---------------------------------------"
db.execute2( "select * from test" ) { |row| puts row.join( ',' ) }

