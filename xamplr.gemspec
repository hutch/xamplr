# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xamplr}
  s.version = "1.3.12"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Hutchison"]
  s.date = %q{2009-06-18}
  s.email = %q{hutch@recursive.ca}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc",
     "README.rdoc.orig"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "CHANGES.txt",
     "COPYING",
     "LICENSE",
     "Makefile",
     "README.rdoc",
     "README.rdoc.orig",
     "Rakefile",
     "VERSION.yml",
     "examples/employees/final-xampl/xampl-gen.rb",
     "examples/employees/final-xampl/xml/ddd-final-xampl.xml",
     "examples/employees/final/xampl-gen.rb",
     "examples/employees/final/xml/ddd-final.xml",
     "examples/employees/first/xampl-gen.rb",
     "examples/employees/first/xml/ddd-first.xml",
     "examples/employees/twist/twist.graphml",
     "examples/employees/twist/xampl-gen.rb",
     "examples/employees/twist/xml/twist.xml",
     "examples/employees/xamplr-twist.xml",
     "examples/employees/yuml-diagrams/DDD-final-approach.graphml",
     "examples/employees/yuml-diagrams/DDD-final-xampl-approach.graphml",
     "examples/employees/yuml-diagrams/DDD-ideal-final-approach.graphml",
     "examples/employees/yuml-diagrams/ddd-final.png",
     "examples/employees/yuml-diagrams/ddd-final.yuml",
     "examples/employees/yuml-diagrams/ddd-first.png",
     "examples/employees/yuml-diagrams/ddd-first.yuml",
     "examples/employees/yuml-diagrams/final-yed.png",
     "examples/employees/yuml-diagrams/first-yed.png",
     "examples/employees/yuml-diagrams/twist.png",
     "examples/employees/yuml-diagrams/twist.yuml",
     "examples/employees/yuml-diagrams/xamplr-final-no-mixins.png",
     "examples/employees/yuml-diagrams/xamplr-final-simplified.png",
     "examples/employees/yuml-diagrams/xamplr-final-with-mixins.png",
     "examples/employees/yuml-diagrams/yuml-simplified.txt",
     "examples/employees/yuml-diagrams/yuml-with-mixins.txt",
     "examples/employees/yuml-diagrams/yuml.txt",
     "examples/hobbies/hobbies.rb",
     "examples/hobbies/xampl-gen.rb",
     "examples/hobbies/xml/hobby.xml",
     "examples/hobbies/xml/people.xml",
     "examples/random-people-shared-addresses/.gitignore",
     "examples/random-people-shared-addresses/Makefile",
     "examples/random-people-shared-addresses/batch-load-users-profiled.rb",
     "examples/random-people-shared-addresses/batch-load-users-safe.rb",
     "examples/random-people-shared-addresses/batch-load-users.rb",
     "examples/random-people-shared-addresses/find-mentions.rb",
     "examples/random-people-shared-addresses/find-people-by-address.rb",
     "examples/random-people-shared-addresses/optimise.rb",
     "examples/random-people-shared-addresses/people.rb",
     "examples/random-people-shared-addresses/query.rb",
     "examples/random-people-shared-addresses/query2.rb",
     "examples/random-people-shared-addresses/random-names.csv",
     "examples/random-people-shared-addresses/settings.rb",
     "examples/random-people-shared-addresses/what-to-query-on.rb",
     "examples/random-people-shared-addresses/xampl-gen.rb",
     "examples/random-people-shared-addresses/xml/people.xml",
     "examples/random-people/.gitignore",
     "examples/random-people/Makefile",
     "examples/random-people/batch-load-users.rb",
     "examples/random-people/optimise.rb",
     "examples/random-people/people.rb",
     "examples/random-people/query.rb",
     "examples/random-people/query2.rb",
     "examples/random-people/random-names.csv",
     "examples/random-people/rawtc.rb",
     "examples/random-people/settings.rb",
     "examples/random-people/what-to-query-on.rb",
     "examples/random-people/xampl-gen.rb",
     "examples/random-people/xml/people.xml",
     "examples/read-testing/.gitignore",
     "examples/read-testing/Makefile",
     "examples/read-testing/load.rb",
     "examples/read-testing/read.rb",
     "examples/read-testing/rrr.rb",
     "examples/read-testing/settings.rb",
     "examples/read-testing/xampl-gen.rb",
     "examples/read-testing/xml/text.xml",
     "examples/tokyo-cabinet-experimental/.gitignore",
     "examples/tokyo-cabinet-experimental/expt-query.rb",
     "examples/tokyo-cabinet-experimental/expt-query2.rb",
     "examples/tokyo-cabinet-experimental/expt-query3.rb",
     "examples/tokyo-cabinet-experimental/expt-reader.rb",
     "examples/tokyo-cabinet-experimental/expt.rb",
     "examples/tokyo-cabinet-experimental/xampl-gen.rb",
     "examples/tokyo-cabinet-experimental/xml/tcx.xml",
     "lib/xampl-generator.rb",
     "lib/xampl.rb",
     "lib/xamplr-generator.rb",
     "lib/xamplr.rb",
     "lib/xamplr/.cvsignore",
     "lib/xamplr/README-POSSIBLE-PROBLEMS",
     "lib/xamplr/TODO",
     "lib/xamplr/exceptions.rb",
     "lib/xamplr/from-xml-orig.rb",
     "lib/xamplr/from-xml.rb",
     "lib/xamplr/gen-elements.xml",
     "lib/xamplr/gen.elements.xml",
     "lib/xamplr/generate-elements.rb",
     "lib/xamplr/generator.rb",
     "lib/xamplr/graphml-out.rb",
     "lib/xamplr/handwritten/example.rb",
     "lib/xamplr/handwritten/hand-example.rb",
     "lib/xamplr/handwritten/test-handwritten.rb",
     "lib/xamplr/indexed-array.rb",
     "lib/xamplr/mixins.rb",
     "lib/xamplr/my.gen.elements.xml",
     "lib/xamplr/notifications.rb",
     "lib/xamplr/obsolete/fsdb.rb",
     "lib/xamplr/persist-to-xml.rb",
     "lib/xamplr/persistence.rb",
     "lib/xamplr/persistence.rb.more_thread_safe",
     "lib/xamplr/persistence.rb.partially_thread_safe",
     "lib/xamplr/persister.rb",
     "lib/xamplr/persisters/caches.rb",
     "lib/xamplr/persisters/caching.rb",
     "lib/xamplr/persisters/filesystem.rb",
     "lib/xamplr/persisters/in-memory.rb",
     "lib/xamplr/persisters/simple.rb",
     "lib/xamplr/persisters/tokyo-cabinet.rb",
     "lib/xamplr/simpleTemplate/danger.rx",
     "lib/xamplr/simpleTemplate/obsolete/input-c.r4",
     "lib/xamplr/simpleTemplate/obsolete/play.r6.txt",
     "lib/xamplr/simpleTemplate/obsolete/play_more.r6.txt",
     "lib/xamplr/simpleTemplate/obsolete/test001.r5",
     "lib/xamplr/simpleTemplate/obsolete/test002.r5",
     "lib/xamplr/simpleTemplate/obsolete/test003.r5",
     "lib/xamplr/simpleTemplate/old/r6.000.rb",
     "lib/xamplr/simpleTemplate/old/r6.001.rb",
     "lib/xamplr/simpleTemplate/play.r6",
     "lib/xamplr/simpleTemplate/play_more.r6",
     "lib/xamplr/simpleTemplate/play_noblanks.r6",
     "lib/xamplr/simpleTemplate/playq.r6",
     "lib/xamplr/simpleTemplate/r6.rb",
     "lib/xamplr/simpleTemplate/simple-template.rb",
     "lib/xamplr/templates/.cvsignore",
     "lib/xamplr/templates/child.template",
     "lib/xamplr/templates/child_indexed.template",
     "lib/xamplr/templates/child_modules.template",
     "lib/xamplr/templates/element_classes.template",
     "lib/xamplr/templates/element_data.template",
     "lib/xamplr/templates/element_empty.template",
     "lib/xamplr/templates/element_mixed.template",
     "lib/xamplr/templates/element_simple.template",
     "lib/xamplr/templates/package.template",
     "lib/xamplr/test-support/Makefile",
     "lib/xamplr/test-support/bench-cache.rb",
     "lib/xamplr/test-support/bench-script.rb",
     "lib/xamplr/test-support/bench.rb",
     "lib/xamplr/test-support/bench2.rb",
     "lib/xamplr/test-support/test-cache.rb",
     "lib/xamplr/test-support/test-data/binding.xml",
     "lib/xamplr/test-support/test-data/example.xml",
     "lib/xamplr/test-support/test-data/internationalization-utf8.txt",
     "lib/xamplr/test-support/test-data/labels.xml",
     "lib/xamplr/test-support/test-data/labels001.xml",
     "lib/xamplr/test-support/test-deep-change.rb",
     "lib/xamplr/test-support/test-elements.rb",
     "lib/xamplr/test-support/test-indexed-array.rb",
     "lib/xamplr/test-support/test-misc.rb",
     "lib/xamplr/test-support/test-names.rb",
     "lib/xamplr/test-support/test-rollback.rb",
     "lib/xamplr/test-support/test.rb",
     "lib/xamplr/to-ruby.rb",
     "lib/xamplr/to-xml.rb",
     "lib/xamplr/version.rb",
     "lib/xamplr/visitor.rb",
     "lib/xamplr/visitors.rb",
     "lib/xamplr/xampl-generator.rb",
     "lib/xamplr/xampl-hand-generated.rb",
     "lib/xamplr/xampl-module.rb",
     "lib/xamplr/xampl-object-internals.rb",
     "lib/xamplr/xampl-object.rb",
     "lib/xamplr/xampl-persisted-object.rb",
     "lib/xamplr/xml-text.rb",
     "lib/xamplr/xml/document.xml",
     "lib/xamplr/xml/elements.xml",
     "lib/xamplr/xml/elements000.xml",
     "lib/xamplr/xml/example.xml",
     "lib/xamplr/xml/options.xml",
     "lib/xamplr/xml/uche.xml",
     "lib/xamplr/yEd-sample.graphml",
     "lib/xamplr/yuml-out.rb",
     "regression/tightly-nested-mutual-mentions/Makefile",
     "regression/tightly-nested-mutual-mentions/build.rb",
     "regression/tightly-nested-mutual-mentions/load.rb",
     "regression/tightly-nested-mutual-mentions/repo-keep.tgz",
     "regression/tightly-nested-mutual-mentions/setup.rb",
     "regression/tightly-nested-mutual-mentions/xampl-gen.rb",
     "regression/tightly-nested-mutual-mentions/xml/stuff.xml",
     "xamplr.gemspec"
  ]
  s.homepage = %q{http://github.com/hutch/xamplr}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{xampl}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{xamplr is the ruby version of xampl}
  s.test_files = [
    "examples/employees/final/xampl-gen.rb",
     "examples/employees/final-xampl/xampl-gen.rb",
     "examples/employees/first/xampl-gen.rb",
     "examples/employees/twist/xampl-gen.rb",
     "examples/hobbies/hobbies.rb",
     "examples/hobbies/xampl-gen.rb",
     "examples/random-people/batch-load-users.rb",
     "examples/random-people/optimise.rb",
     "examples/random-people/people.rb",
     "examples/random-people/query.rb",
     "examples/random-people/query2.rb",
     "examples/random-people/rawtc.rb",
     "examples/random-people/settings.rb",
     "examples/random-people/what-to-query-on.rb",
     "examples/random-people/xampl-gen.rb",
     "examples/random-people-shared-addresses/batch-load-users-profiled.rb",
     "examples/random-people-shared-addresses/batch-load-users-safe.rb",
     "examples/random-people-shared-addresses/batch-load-users.rb",
     "examples/random-people-shared-addresses/find-mentions.rb",
     "examples/random-people-shared-addresses/find-people-by-address.rb",
     "examples/random-people-shared-addresses/optimise.rb",
     "examples/random-people-shared-addresses/people.rb",
     "examples/random-people-shared-addresses/query.rb",
     "examples/random-people-shared-addresses/query2.rb",
     "examples/random-people-shared-addresses/settings.rb",
     "examples/random-people-shared-addresses/what-to-query-on.rb",
     "examples/random-people-shared-addresses/xampl-gen.rb",
     "examples/read-testing/load.rb",
     "examples/read-testing/read.rb",
     "examples/read-testing/rrr.rb",
     "examples/read-testing/settings.rb",
     "examples/read-testing/xampl-gen.rb",
     "examples/tokyo-cabinet-experimental/expt-query.rb",
     "examples/tokyo-cabinet-experimental/expt-query2.rb",
     "examples/tokyo-cabinet-experimental/expt-query3.rb",
     "examples/tokyo-cabinet-experimental/expt-reader.rb",
     "examples/tokyo-cabinet-experimental/expt.rb",
     "examples/tokyo-cabinet-experimental/xampl-gen.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hutch-xamplr-pp>, [">= 1.1.2"])
      s.add_runtime_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    else
      s.add_dependency(%q<hutch-xamplr-pp>, [">= 1.1.2"])
      s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    end
  else
    s.add_dependency(%q<hutch-xamplr-pp>, [">= 1.1.2"])
    s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
  end
end
