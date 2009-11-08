
is_darwin = RUBY_PLATFORM.include? 'darwin'

#output = (1..1000000).to_a.inspect
output = (1..1000).to_a.inspect

file_name = "./junk.out"

ss = Time.now
10.times do | i |
  s = Time.now
  File.open("./junk-a-#{ i }.out", 'w') { | f | f.print output; f.fsync }
  puts "time puts: #{ Time.now - s }"
end

puts "TOTAL: #{ Time.now - ss}\n"

ss = Time.now
10.times do | i |
  s = Time.now
  File.open("./junk-b-#{ i }.out", 'w') do | f |
    f.write output
    f.fsync
    if is_darwin then
      f.fcntl(51, 0) # Attempt an F_FULLFSYNC fcntl to commit data to disk
    end
  end
  puts "time sync write: #{ Time.now - s }"
end

puts "TOTAL: #{ Time.now - ss}\n"

ss = Time.now
10.times do | i |
  s = Time.now
  File.open("./junk-b-#{ i }.out", 'w') { | f | f.write output }
  puts "time write: #{ Time.now - s }"
end

puts "TOTAL: #{ Time.now - ss}\n"
