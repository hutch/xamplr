#! /usr/bin/env ruby

require "xamplr/simpleTemplate/simple-template"

###
###  and this is how it can be used...
###

# Define a class to hold the template methods. Any attributes defined by this
# class will be available to be used by the templates when they are 'run'.
# These are expected to be set up by the template-invoking program. This
# class defines a single attribute 'message' 

class R6_Template
  include TemplateEngine
  attr_accessor :message
end

# Now we need to get some templates into place. We are providing a list of
# files here, but it is possible to imagine using ARGS to get filenames from
# the command line. Simply pass the list to the compile_script method.

files = [ "play.r6", "play_more.r6", "playq.r6", "play_noblanks.r6"];

engine = R6_Template.new
engine.compile_scripts(files)

# For illustrative purposes, go over the file arguments and execute
# the corresponding method defined above. The file names are used by the
# Template Engine to create a method that, when called, will 'execute' the
# template. The method name will be chosen by removing the filename extension.

files.each { | script_name |
  method_name = File::basename(script_name, ".*")

  # just a silly message that identifies the script that is running
  engine.message = sprintf("this is script '%s'", method_name)

  puts "#{method_name}*******************"
  what = engine.send(method_name);
  puts "{{{#{what}}}}*******************"
}

# This time call the play method directly. There must be a template
# called 'play' for this to work.

engine.message = "this is script 'play' -- called explicitly"
puts "!!play!!*******************"
what = engine.play()
puts "{{{#{what}}}}*******************"

# Now do the same thing as the illustrative loop above but writing to a file
# with the script name and a ".out" extension.

files.each { | script_name |
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
files.each { | script_name |
  method_name = File::basename(script_name, ".*")
  engine.message = sprintf("this is script '%s'", method_name)
  what = engine.send(method_name, long_string);
}
puts "!!{{{#{long_string}}}}!!*******************"

# This will fail, because the template methods are only defined on the
# instance of the engine that compiled them.
#
#engine2 = R6_Template.new
#engine2.message = "this is script 'play' -- called explicitly"
#File.open("play-x.out", "w") { | file |
#  engine2.play(file)
#}
