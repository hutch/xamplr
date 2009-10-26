
diagram = ""
File.open("./generated.yuml") do | f |
  f.each do | line |
    diagram << line.chomp
  end
end
wget = "wget 'http://yuml.me/diagram/scruffy/class/#{diagram}' -O 'generated.png'"
#wget = "wget 'http://yuml.me/diagram/scruffy/class/#{diagram}.pdf' -O 'generated.pdf'"
`#{wget}`
