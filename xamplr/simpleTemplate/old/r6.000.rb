#! /usr/bin/env ruby
module TemplateEngine
  attr_accessor :files

  def macro(name, &block)
    Kernel.send(:define_method, name) { |*args|
      puts block.call(args)
    }
  end

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

    File.open(template_file_name) do | file |
      r = "
  def #{method_name}(result=\"\")
		tmp = ""
    result << \"\"
"
      while line = file.gets
        if line[0] == ?|
          r << "   #{line[1..-1]}"
        else
          r << "    result << \"#{line.chomp.gsub("\"", "\\\"")}\\n\"\n"
        end
      end
      r << "
    result
  end
"
    end
  end

	def compile_scripts()
    files.each { | script_name |
      method_name = File::basename(script_name, ".*")
      the_script = build_script(script_name, method_name)
      puts the_script
      instance_eval the_script
    }
  end
end

###
###  and this is how it can be used...
###

# Define a class to hold the template methods. There is an attribute 'message'
# that can be set by the program invoking the template, and referred to by the
# templates.

class R6_Template
  include TemplateEngine
  attr_accessor :message
end

# Assume that the command line arguments are all specifying the names of a
# template file. Open the file and pass it to the build script method. When
# the script is built, 'eval' it.

engine = R6_Template.new
engine.files = [ "play.r6", "play_more.r6", "playq.r6"];
engine.compile_scripts

exit

# For illustrative purposes, go over the command line arguments and execute
# the corresponding method defined above.

engine.files.each { | script_name |
  method_name = File::basename(script_name, ".*")
  engine.message = sprintf("this is script '%s'", method_name)
  puts "#{method_name}*******************"
  what = engine.send(method_name);
  puts "{{{#{what}}}}*******************"
}

# This time call the play method directly. There must be a template
# called 'play' (sans extenstion) for this to work.

engine.message = "this is script 'play' -- called explicitly"
puts "!!play!!*******************"
what = engine.play()
puts "{{{#{what}}}}*******************"

# Now do the same thing as the illustrative loop above but writing to a file
# with the script name and a ".out" extension.

engine.files.each { | script_name |
  method_name = File::basename(script_name, ".*")
  engine.message = sprintf("this is script '%s'", method_name)
  File.open(sprintf("%s.out", method_name), "w") { | file |
    engine.send(method_name, file);
  }
}

# Write to a file called "play-x.out", again, there must be a play template
# defined.

engine.message = "this is script 'play' -- called explicitly"
File.open("play-x.out", "w") { | file |
  engine.play(file)
}

# Build up a single string by applying all the templates
long_string = ""
engine.files.each { | script_name |
  method_name = File::basename(script_name, ".*")
  engine.message = sprintf("this is script '%s'", method_name)
  what = engine.send(method_name, long_string);
}
puts "!!{{{#{long_string}}}}!!*******************"

