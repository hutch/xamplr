
diagram = ""
File.open("./generated-elements.yuml") do | f |
  f.each do | line |
    diagram << line.chomp
  end
end
wget = "wget 'http://yuml.me/diagram/scruffy/class/#{diagram}' -O 'generated-elements.png'"
#wget = "wget 'http://yuml.me/diagram/scruffy/class/#{diagram}.pdf' -O 'generated-elements.pdf'"
`#{wget}`
