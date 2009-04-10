#!/usr/bin/env ruby

require "test/unit"

require "xampl-generator"

include XamplGenerator
include Xampl

class TestXampl < Test::Unit::TestCase

  def setup
    Xampl.disable_all_persisters
    FromXML.reset_registry
  end

  def test_tokenise
    assert_equal(nil, FromXML.tokenise_string(nil))
    assert_equal("", FromXML.tokenise_string(""))
    assert_equal("abc", FromXML.tokenise_string("abc"))
    assert_equal("abc def ghi", FromXML.tokenise_string("abc def ghi"))
    assert_equal("a b c", FromXML.tokenise_string("a b c"))
    assert_equal("a b c", FromXML.tokenise_string(" a b c"))
    assert_equal("a b c", FromXML.tokenise_string("a b c "))
    assert_equal("a b c", FromXML.tokenise_string(" a b c "))
    assert_equal("a b c", FromXML.tokenise_string("a    b    c"))
    assert_equal("a b c", FromXML.tokenise_string("a\nb\tc"))
    assert_equal("a b c", FromXML.tokenise_string("a\n\t\n\tb\t\n\t\nc"))
    assert_equal("a b c", FromXML.tokenise_string("\n\n\t\ta\n\t\n\tb\t\n\t\nc\n\n"))
    assert_equal("abc", FromXML.tokenise_string("\n abc"))

    str = "\n\n\t\ta\n\t\n\tb\t\n\t\nc\n\n"
    FromXML.tokenise_string str
    assert_equal("a b c", str)

    #assert_equal(" a b c", FromXML.tokenise_string(" a b c", false))
    #assert_equal(" a b c", FromXML.tokenise_string("    a b c", false))
    #assert_equal(" a b c", FromXML.tokenise_string("\n\n\t    a b c", false))
  end

  def test_xml_text
    xml=%Q{
<unknown a='1'
         b='2'
         xmlns='dummy.ns'
         xmlns:ns='another-dummy.ns'
         xmlns:ns1='never-used.ns'
         xmlns:ns2='used-only-by-attr.ns'>
  hello <ns:strong ns2:c='3'
                   ns3:d='4'
                   xmlns:ns3='also-used-only-by-attr.ns'>there</ns:strong>
  hello <strong ns2:c='3'
                ns3:d='4'
                xmlns='another-dummy.ns'
                xmlns:ns3='also-used-only-by-attr.ns'>there</strong>
</unknown>
}
    xml_expected=%Q{<unknown a='1' b='2' xmlns:ns='another-dummy.ns' xmlns:ns2='used-only-by-attr.ns' xmlns:ns3='also-used-only-by-attr.ns' xmlns='dummy.ns'>
  hello <ns:strong ns2:c='3' ns3:d='4' xmlns='another-dummy.ns'>there</ns:strong>
  hello <strong ns2:c='3' ns3:d='4' xmlns='another-dummy.ns'>there</strong>
</unknown>}
    pp = FromXML.new
    pp.setup_parse_string(xml)
    while !pp.startElement?
      pp.nextEvent
    end
    xml_text = XMLText.new
    xml_text.build(pp)

    assert_equal(xml_expected, xml_text.text)
  end
end

