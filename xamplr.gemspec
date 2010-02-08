# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{xamplr}
  s.version = "1.9.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Hutchison"]
  s.date = %q{2010-02-08}
  s.description = %q{xamplr is the ruby version of xampl.}
  s.email = %q{hutch@recursive.ca}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "CHANGES.txt",
     "COPYING",
     "LICENSE",
     "Makefile",
     "README.md",
     "Rakefile",
     "VERSION.yml",
     "lib/xampl.rb",
     "lib/xamplr.rb",
     "lib/xamplr/.cvsignore",
     "lib/xamplr/README-POSSIBLE-PROBLEMS",
     "lib/xamplr/TODO",
     "lib/xamplr/TYPES.txt",
     "lib/xamplr/exceptions.rb",
     "lib/xamplr/from-xml-orig.rb",
     "lib/xamplr/from-xml.rb",
     "lib/xamplr/indexed-array.rb",
     "lib/xamplr/iterator.rb",
     "lib/xamplr/mixins.rb",
     "lib/xamplr/notifications.rb",
     "lib/xamplr/persist-to-xml.rb",
     "lib/xamplr/persistence.rb",
     "lib/xamplr/persister.rb",
     "lib/xamplr/persisters/caches.rb",
     "lib/xamplr/persisters/caching.rb",
     "lib/xamplr/persisters/dumb.rb",
     "lib/xamplr/persisters/filesystem.rb",
     "lib/xamplr/persisters/in-memory.rb",
     "lib/xamplr/persisters/mongo.rb",
     "lib/xamplr/persisters/simple.rb",
     "lib/xamplr/persisters/tokyo-cabinet.rb",
     "lib/xamplr/persisters/tokyo-cabinet.rb.1-DB",
     "lib/xamplr/persisters/tokyo-cabinet.rb.N-DB",
     "lib/xamplr/persisters/tokyo-cabinet.rb.NICE-TRY",
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
     "lib/xamplr/visitor.rb",
     "lib/xamplr/visitors.rb",
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
     "regression/.gitignore",
     "regression/parsing-namespaced-xml/Makefile",
     "regression/parsing-namespaced-xml/README",
     "regression/parsing-namespaced-xml/project-generator.rb",
     "regression/parsing-namespaced-xml/simple.rb",
     "regression/parsing-namespaced-xml/xml/simple.xml",
     "regression/require-within-generated-code/project-generator.rb",
     "regression/require-within-generated-code/test.rb",
     "regression/require-within-generated-code/xml/customers.xml",
     "regression/require-within-generated-code/xml/docmodel.xml",
     "regression/tc-indexes-crossing-pid-boundaries/Makefile",
     "regression/tc-indexes-crossing-pid-boundaries/bad-idea.rb",
     "regression/tc-indexes-crossing-pid-boundaries/fail-badly.rb",
     "regression/tc-indexes-crossing-pid-boundaries/fail.rb",
     "regression/tc-indexes-crossing-pid-boundaries/fucking-bad-idea.rb",
     "regression/tc-indexes-crossing-pid-boundaries/setup.rb",
     "regression/tc-indexes-crossing-pid-boundaries/xml/bad-idea.xml",
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
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{xamplr is the ruby version of xampl}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<xamplr-pp>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    else
      s.add_dependency(%q<xamplr-pp>, [">= 1.2.0"])
      s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
    end
  else
    s.add_dependency(%q<xamplr-pp>, [">= 1.2.0"])
    s.add_dependency(%q<libxml-ruby>, [">= 1.1.3"])
  end
end

