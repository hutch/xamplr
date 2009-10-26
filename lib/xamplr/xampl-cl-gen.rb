
require 'xamplr-generator'

include XamplGenerator
include Xampl

class ProjectGenerator

  def directory
    File.join(%w{ . xampl_generated_code })
  end

  def filenames
    Dir.glob("./xml/**/*.xml")
  end

  def print_base_filename
    File.join(%w{ . generated })
  end

  def print_options
    # return an array containing any (or none) of:
    #    :schema    -- a schema-like xml representation of the generated code
    #    :graphml   -- a graphml file describing the class model (compatible with yEd)
    #    :yuml      -- a yuml file that represents a simplified class model (compatible with yUML)

    # [:schema, :graphml, :yuml]
    []
  end

  def print
    nil
  end

  def persisted_attributes
    %w{ pid }
  end

  def indexed_attributes
    %w{ id }
  end

  def resolve_namespaces
    # any array of arrays
    # each sub-array:
    #    0: a string or an array of strings, containing xml namespaces found in the example xml files
    #       an empty string is the default namespace
    #    1: a ruby Module name (get the cases right)
    #    2: a namespace prefix used when writing xml, optional. A generated prefix will be used otherwise.
    []
  end

  def generate

#      Xampl.set_default_persister_kind(:simple)
    Xampl.set_default_persister_kind(:in_memory)
#      Xampl.set_default_persister_kind(:filesystem)
#      Xampl.set_default_persister_kind(:tokyo_cabinet)
#      Xampl.set_default_persister_format(:xml_format)

    Xampl.transaction("project-generation") do

      options = Options.new do | opts |
        persisted_attributes.each do | pattr |
          opts.new_index_attribute(pattr).persisted = true
        end

        indexed_attributes.each do | iattr |
          opts.new_index_attribute(iattr)
        end

        resolve_namespaces.each do | namespace, ruby_module_name, output_ns_prefix |
          opts.resolve(namespace, ruby_module_name, output_ns_prefix)
        end

      end

      generator = Generator.new('generator')
      generator.go(:options => options,
                   :filenames => filenames,
                   :directory => directory)

      puts generator.print_elements(print_base_filename, print_options)

      Xampl.rollback
    end
  end
end

