# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "xamplr"
  s.version = "1.9.19"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Bob Hutchison"]
  s.date = "2012-07-21"
  s.description = "xamplr is the ruby version of xampl."
  s.email = "hutch@recursive.ca"
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
     "lib/Makefile",
     "lib/xampl.rb",
     "lib/xamplr.rb",
     "lib/xamplr/.cvsignore",
     "lib/xamplr/README-POSSIBLE-PROBLEMS",
     "lib/xamplr/TODO",
     "lib/xamplr/TYPES.txt",
     "lib/xamplr/exceptions.rb",
     "lib/xamplr/from-xml-orig.rb",
     "lib/xamplr/from-xml.rb",
     "lib/xamplr/from-xml.rb.libxml",
     "lib/xamplr/from-xml.rb.nokogiri",
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
     "lib/xamplr/persisters/mongo.rb.cannot-use",
     "lib/xamplr/persisters/redis.rb",
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
     "lib/xamplr/tests/.gitignore",
     "lib/xamplr/tests/redis/Makefile",
     "lib/xamplr/tests/redis/author.rb",
     "lib/xamplr/tests/redis/project-generator.rb",
     "lib/xamplr/tests/redis/redis_spec.rb",
     "lib/xamplr/tests/redis/spec.opts",
     "lib/xamplr/tests/redis/spec_helper.rb",
     "lib/xamplr/tests/redis/testing-db/.gitignore",
     "lib/xamplr/tests/redis/testing-db/Makefile",
     "lib/xamplr/tests/redis/testing-db/unit-testing.redis.conf",
     "lib/xamplr/tests/redis/xml/redis-test.xml",
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
  s.homepage = "http://github.com/hutch/xamplr"
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "xamplr is the ruby version of xampl"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<xamplr-pp>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.5.5"])
    else
      s.add_dependency(%q<xamplr-pp>, [">= 1.2.0"])
      s.add_dependency(%q<nokogiri>, [">= 1.5.5"])
    end
  else
    s.add_dependency(%q<xamplr-pp>, [">= 1.2.0"])
    s.add_dependency(%q<nokogiri>, [">= 1.5.5"])
  end
end
