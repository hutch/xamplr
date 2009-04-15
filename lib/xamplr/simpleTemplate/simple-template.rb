module TemplateEngine
  attr_accessor :method_to_file_name, :file_name_to_method

  def initialize
    @method_to_file_name = Hash.new()
    @file_name_to_method = Hash.new()
  end

  #  def macro(name, &block)
  #    Kernel.send(:define_method, name) { |*args|
  #      puts block.call(args)
  #    }
  #  end

  def build_script(template_file_name, method_name)

    # Build the definition of a method (called 'method_name') that
    # will execute the template (in the file 'template_file_name'). There will
    # be an optional argument that defaults to the empty string (and so this
    # method will, by default, build a new string representing the result). If
    # the argument is supplied, it must respond to the "<<" (append) method.
    #
    # The result variable is available in the template. To write to the result
    # from Ruby code, result << sprintf("hello %s", "world") in the template
    # will get its output where expected.

    found_template_file_name = nil
    $LOAD_PATH.each{ | directory |
      possible_template_file_name = File.join(directory, template_file_name)
      if File.exists?(possible_template_file_name)
        found_template_file_name = possible_template_file_name
      end
    }
    return unless found_template_file_name
    File.open(found_template_file_name) do | file |
      tmp = ""
      r = "
  def #{method_name}(result=\"\")
    result << \"\"
      "
      while line = file.gets
        if line[0] == ?|
          if (0 < tmp.length)
            r << "    result << \"#{tmp.gsub("\"", "\\\"")}\""
            tmp = ""
          end
          r << "   #{line[1..-1]}"
        else
          #tmp << line.chomp << "\n"
          tmp << line
        end
      end
      r << "    result << \"#{tmp.gsub("\"", "\\\"")}\""
      r << "
    result
  end
"
    end
  end

  def compile_scripts(files)
    files.each { | script_name |
      method_name = File::basename(script_name, ".*")
      #puts "COMPILE: [[#{method_name}]]"

      @method_to_file_name[method_name] = script_name;
      @file_name_to_method[script_name] = method_name;

      the_script = build_script(script_name, method_name)
      #puts the_script
      instance_eval(the_script, "SCRIPT:#{script_name}", 1)
    }
  end
end

