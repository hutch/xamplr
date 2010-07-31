require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Xampl

  describe 'redis creation' do
    before :each do
      Xampl.drop_all_persisters
    end
    after :each do
    end

    it 'will create a named instance of the redis persister' do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis = Xampl.create_named_persister(repo_name, :redis)

      redis.should be_an_instance_of(RedisPersister)
      redis.repo_name.should == repo_name

      redis.should == Xampl.find_named_persister(repo_name)
    end

    it 'will insist that it is named when created' do
      lambda do
        Xampl.create_named_persister(nil, :redis)
      end.should raise_exception(NoAnonymousPersisters)
    end

    it 'will not cache anything but persisted xampl objects' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      lambda do
        redis.cache("hello")
      end.should raise_exception(NotXamplPersistedObject)
    end

    it 'will generate useful keys' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new(XamplTestRedis.scratch_name('xo'))
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new(XamplTestRedis.scratch_name('xo'))

      puts "\n\n#{ redis.key_for_xampl(thing1) }\n"

      redis.key_for_class(thing1.class, thing1.get_the_index).should == redis.key_for_class(thing1.class, thing1.get_the_index)
      redis.key_for_xampl(thing1).should == redis.key_for_xampl(thing1)
      redis.key_for_class(thing1.class, thing1.get_the_index).should == redis.key_for_xampl(thing1)

      redis.key_for_xampl(thing1).should_not == redis.key_for_xampl(thing2)
    end

    it 'will generate different keys for different repositories' do
      redis1 = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)
      redis2 = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis1.key_for_class(thing.class, thing.get_the_index).should_not == redis2.key_for_class(thing.class, thing.get_the_index).should
      redis1.key_for_xampl(thing).should_not == redis2.key_for_xampl(thing).should_not
    end

    it 'will cache a xampl object' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.cache(thing)
      found = redis.read_from_cache(thing.class, thing.get_the_index)

      found.should == thing
      found.should be_an_instance_of(XamplTestRedis::DroolingIdiotPersistedObject)
    end

    it 'will moan if two different objects are cached under the same key' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.cache(thing1)
      lambda do
        redis.cache(thing2)
      end.should raise_exception(DuplicateXamplInPersister)

      found = redis.read_from_cache(thing1.class, thing1.get_the_index)
      found.should == thing1
    end

    it 'will store if two different objects are cached under the same key if the first is removed from the cache first' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.cache(thing1)
      uncached = redis.uncache(thing1)
      uncached.should == thing1

      redis.cache(thing2)

      found = redis.read_from_cache(thing2.class, thing2.get_the_index)
      found.should == thing2
    end

    it "will clear its caches" do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.cache(thing)
      redis.clear_cache
      found = redis.read_from_cache(thing.class, thing.get_the_index)

      found.should be_nil
    end

    it 'will have weak cache references' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing_referenced = XamplTestRedis::DroolingIdiotPersistedObject.new('referenced')

      redis.cache(thing_referenced)
      redis.cache(XamplTestRedis::DroolingIdiotPersistedObject.new('unreferenced'))

      GC.start

      redis.read_from_cache(XamplTestRedis::DroolingIdiotPersistedObject, 'referenced').should == thing_referenced
      redis.read_from_cache(XamplTestRedis::DroolingIdiotPersistedObject, 'unreferenced').should be_nil
    end

    it 'will two different objects are cached under the same key if the first is GCed' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      redis.cache(XamplTestRedis::DroolingIdiotPersistedObject.new('test'))
      GC.start
      redis.cache(XamplTestRedis::DroolingIdiotPersistedObject.new('test'))
    end

    it 'will establish a redis connection' do
      pending
    end

    it 'will not open a new connection if one already exists' do
      pending
    end

    it "will close its redis connection" do
      pending
    end

    it 'will re-establish a redis connection' do
      pending
    end

#    it 'can set options' do
#      create_named_persister('t1', :redis)
#      pending
#    end

#    it "will zzz" do
#      pending
#    end

  end

end
