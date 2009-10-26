class ProjectGenerator

  def resolve_namespaces
    # any array of arrays
    # each sub-array:
    #    0: a string or an array of strings, containing xml namespaces found
    #       in the example xml files an empty string is the default namespace
    #    1: a ruby Module name (get the character cases right)
    #    2: a namespace prefix used when writing xml, optional. A generated
    #       prefix will be used otherwise.

    #[]

    [
            [ 'com.xampl.intro.example2', 'Example2', 'ex2']
    ]


  end

end

