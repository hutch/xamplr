# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xamplr}
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Hutchison"]
  s.date = %q{2009-04-27}
  s.email = %q{hutch@recursive.ca}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "CHANGES.txt",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "examples/random-people-shared-addresses/Makefile",
    "examples/random-people-shared-addresses/batch-load-users.rb",
    "examples/random-people-shared-addresses/find-mentions.rb",
    "examples/random-people-shared-addresses/find-people-by-address.rb",
    "examples/random-people-shared-addresses/optimise.rb",
    "examples/random-people-shared-addresses/people.rb",
    "examples/random-people-shared-addresses/query.rb",
    "examples/random-people-shared-addresses/query2.rb",
    "examples/random-people-shared-addresses/random-names.csv",
    "examples/random-people-shared-addresses/what-to-query-on.rb",
    "examples/random-people-shared-addresses/xampl-gen.rb",
    "examples/random-people-shared-addresses/xml/people.xml",
    "examples/random-people/Makefile",
    "examples/random-people/batch-load-users.rb",
    "examples/random-people/optimise.rb",
    "examples/random-people/people.rb",
    "examples/random-people/query.rb",
    "examples/random-people/query2.rb",
    "examples/random-people/random-names.csv",
    "examples/random-people/rawtc.rb",
    "examples/random-people/what-to-query-on.rb",
    "examples/random-people/xampl-gen.rb",
    "examples/random-people/xml/people.xml",
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
    "lib/xamplr/README-POSSIBLE-PROBLEMS",
    "lib/xamplr/TODO",
    "lib/xamplr/from-xml.rb",
    "lib/xamplr/gen-elements.xml",
    "lib/xamplr/gen.elements.xml",
    "lib/xamplr/generate-elements.rb",
    "lib/xamplr/generator.rb",
    "lib/xamplr/handwritten/example.rb",
    "lib/xamplr/handwritten/hand-example.rb",
    "lib/xamplr/handwritten/test-handwritten.rb",
    "lib/xamplr/indexed-array.rb",
    "lib/xamplr/mixins.rb",
    "lib/xamplr/my.gen.elements.xml",
    "lib/xamplr/notifications.rb",
    "lib/xamplr/obsolete/fsdb.rb",
    "lib/xamplr/persistence.rb",
    "lib/xamplr/persistence.rb.more_thread_safe",
    "lib/xamplr/persistence.rb.partially_thread_safe",
    "lib/xamplr/persister/caches.rb",
    "lib/xamplr/persister/caching.rb",
    "lib/xamplr/persister/filesystem.rb",
    "lib/xamplr/persister/in-memory.rb",
    "lib/xamplr/persister/simple.rb",
    "lib/xamplr/persister/subversion.rb",
    "lib/xamplr/persister/tokyo-cabinet.rb",
    "lib/xamplr/rac.sh",
    "lib/xamplr/rac_gen.sh",
    "lib/xamplr/simpleTemplate/danger.rx",
    "lib/xamplr/simpleTemplate/input-c.r4",
    "lib/xamplr/simpleTemplate/old/r6.000.rb",
    "lib/xamplr/simpleTemplate/old/r6.001.rb",
    "lib/xamplr/simpleTemplate/play.r6",
    "lib/xamplr/simpleTemplate/play.r6.txt",
    "lib/xamplr/simpleTemplate/play_more.r6",
    "lib/xamplr/simpleTemplate/play_more.r6.txt",
    "lib/xamplr/simpleTemplate/play_noblanks.r6",
    "lib/xamplr/simpleTemplate/playq.r6",
    "lib/xamplr/simpleTemplate/r6.rb",
    "lib/xamplr/simpleTemplate/simple-template.rb",
    "lib/xamplr/simpleTemplate/test001.r5",
    "lib/xamplr/simpleTemplate/test002.r5",
    "lib/xamplr/simpleTemplate/test003.r5",
    "lib/xamplr/templates/child.template",
    "lib/xamplr/templates/child_indexed.template",
    "lib/xamplr/templates/child_indexed.template.000",
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
    "lib/xamplr/xampl-generator.rb",
    "lib/xamplr/xampl-hand-generated.rb",
    "lib/xamplr/xampl-object.rb",
    "lib/xamplr/xml/document.xml",
    "lib/xamplr/xml/elements.xml",
    "lib/xamplr/xml/elements000.xml",
    "lib/xamplr/xml/example.xml",
    "lib/xamplr/xml/options.xml",
    "lib/xamplr/xml/uche.xml",
    "test/test_helper.rb",
    "test/xamplr_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hutch/xamplr}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{xamplr is the ruby version of xampl}
  s.test_files = [
    "test/test_helper.rb",
    "test/xamplr_test.rb",
    "examples/random-people/batch-load-users.rb",
    "examples/random-people/optimise.rb",
    "examples/random-people/people.rb",
    "examples/random-people/query.rb",
    "examples/random-people/query2.rb",
    "examples/random-people/rawtc.rb",
    "examples/random-people/what-to-query-on.rb",
    "examples/random-people/xampl-gen.rb",
    "examples/random-people-shared-addresses/batch-load-users.rb",
    "examples/random-people-shared-addresses/find-mentions.rb",
    "examples/random-people-shared-addresses/find-people-by-address.rb",
    "examples/random-people-shared-addresses/optimise.rb",
    "examples/random-people-shared-addresses/people.rb",
    "examples/random-people-shared-addresses/query.rb",
    "examples/random-people-shared-addresses/query2.rb",
    "examples/random-people-shared-addresses/what-to-query-on.rb",
    "examples/random-people-shared-addresses/xampl-gen.rb",
    "examples/tokyo-cabinet-experimental/expt-query.rb",
    "examples/tokyo-cabinet-experimental/expt-query2.rb",
    "examples/tokyo-cabinet-experimental/expt-query3.rb",
    "examples/tokyo-cabinet-experimental/expt-reader.rb",
    "examples/tokyo-cabinet-experimental/expt.rb",
    "examples/tokyo-cabinet-experimental/xampl-gen.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<hutch-xamplr-pp>, [">= 0"])
    else
      s.add_dependency(%q<hutch-xamplr-pp>, [">= 0"])
    end
  else
    s.add_dependency(%q<hutch-xamplr-pp>, [">= 0"])
  end
end
