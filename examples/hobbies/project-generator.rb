class ProjectGenerator

  def print_options
    # return an array containing any (or none) of:
    #    :schema    -- a schema-like xml representation of the generated code
    #    :graphml   -- a graphml file describing the class model (compatible with yEd)
    #    :yuml      -- a yuml file that represents a simplified class model (compatible with yUML)

    [ :yuml ]
  end

  def resolve_namespaces
    # any array of arrays
    # each sub-array:
    #    0: a string or an array of strings, containing xml namespaces found
    #       in the example xml files an empty string is the default namespace
    #    1: a ruby Module name (get the character cases right)
    #    2: a namespace prefix used when writing xml, optional. A generated
    #       prefix will be used otherwise.

    [
            [ 'http://xampl.com/hobbies', 'Hobbies', 'h']
    ]
  end
end
