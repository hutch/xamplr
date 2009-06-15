require 'rubygems'
require 'libxml'

xml = %Q{
<root pid='aaaaa'
      xmlns:x="http://xampl.com/extra"
      xmlns="http://xampl.com/performance">
    <text pid='bbbb'
          x:size='ccccc'
          stuff='ddddd'>
        actual text &quot; well?
        actual text &quot; well?
        actual text &quot; well?
        actual text &quot; well?
        xxxxx <![CDATA[ <>"'& ]]> xxxxx
    </text>
<nothing/>
    <x:blob v='blob value'/>
</root>
}

reader = LibXML::XML::Reader.string(xml,
                                    :options => LibXML::XML::Parser::Options::NOENT |
                                            LibXML::XML::Parser::Options::NONET |
                                            LibXML::XML::Parser::Options::NOCDATA |
                                            LibXML::XML::Parser::Options::DTDATTR |
                                            LibXML::XML::Parser::Options::NSCLEAN |
                                            # LibXML::XML::Parser::Options::COMPACT |
                                            0)

while reader.read do
  #  puts reader.node_type
  #  puts "line: #{ reader.line_number }, column: #{ reader.column_number }"

  case reader.node_type
#    when LibXML::XML::Reader::TYPE_ATTRIBUTE
    #      puts "attribute"
    when LibXML::XML::Reader::TYPE_DOCUMENT
      puts "DOCUMENT"
    when LibXML::XML::Reader::TYPE_ELEMENT
      attribute_count = reader.attribute_count
      puts "element #{ reader.local_name }, ns: #{ reader.namespace_uri }, #attributes: #{ attribute_count }, depth: #{ reader.depth }"
      if reader.has_attributes? then
        reader.move_to_first_attribute
        attribute_count.times do | i |
          next if reader.namespace_declaration?
          puts "      attr[#{ i }]:: lname: #{ reader.local_name }, ns: #{ reader.namespace_uri } ---> #{ reader.value }"
          reader.move_to_next_attribute
        end
      end

    when LibXML::XML::Reader::TYPE_END_ELEMENT
      puts "END ELEMENT"
    when LibXML::XML::Reader::TYPE_TEXT
      puts "TEXT [[#{ reader.read_string }]]"
    when LibXML::XML::Reader::TYPE_CDATA
      puts "CDATA [[#{ reader.read_string }]]"
    when LibXML::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE
      puts "SIGNIFICANT white space [[#{ reader.read_string }]]"
    when LibXML::XML::Reader::TYPE_ENTITY_REFERENCE
      puts "entity ref"
    when LibXML::XML::Reader::TYPE_WHITESPACE
      puts "whitespace"
    when LibXML::XML::Reader::TYPE_PROCESSING_INSTRUCTION
      puts "processing instruction"
    when LibXML::XML::Reader::TYPE_COMMENT
      puts "comment"
    when LibXML::XML::Reader::TYPE_DOCUMENT_TYPE
      puts "doc type"

    when LibXML::XML::Reader::TYPE_XML_DECLARATION
      puts "xml decl"
    when LibXML::XML::Reader::TYPE_NONE
      puts "NONE!!"
    when LibXML::XML::Reader::TYPE_NOTATION
      puts "notifiation"
    when LibXML::XML::Reader::TYPE_DOCUMENT_FRAGMENT
      puts "doc fragment"
    when LibXML::XML::Reader::TYPE_ENTITY
      puts "entity"
    when LibXML::XML::Reader::TYPE_END_ENTITY
      puts "
      end entity"
    else
      puts "UNKNOWN: #{reader.node_type}"
  end

end
