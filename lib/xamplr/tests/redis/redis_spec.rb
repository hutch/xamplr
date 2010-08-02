require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

module Xampl

  describe 'redis creation and connections' do
    before :each do
      Xampl.drop_all_persisters
      Xampl.set_default_persister_properties(:testing => true,
                                             :allow_connections => false,
                                             :connect_to_known => false,
                                             :connect_to_unknown => false)
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
        redis.perm_cache("hello")
      end.should raise_exception(NotXamplPersistedObject)
    end

    it 'will generate useful keys' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new(XamplTestRedis.scratch_name('xo'))
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new(XamplTestRedis.scratch_name('xo'))

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

      redis.perm_cache(thing)
      found, target = redis.read_from_cache(thing.class, thing.get_the_index)

      found.should == thing
      found.should be_an_instance_of(XamplTestRedis::DroolingIdiotPersistedObject)
      target.should be_nil
    end

    it 'will moan if two different objects are cached under the same key' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.perm_cache(thing1)
      lambda do
        redis.perm_cache(thing2)
      end.should raise_exception(DuplicateXamplInPersister)

      found, target = redis.read_from_cache(thing1.class, thing1.get_the_index)
      found.should == thing1
      target.should be_nil
    end

    it 'will store if two different objects are cached under the same key if the first is removed from the cache first' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing1 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')
      thing2 = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.perm_cache(thing1)
      uncached = redis.perm_uncache(thing1)
      uncached.should == thing1

      redis.perm_cache(thing2)

      found, target = redis.read_from_cache(thing2.class, thing2.get_the_index)
      found.should == thing2
      target.should be_nil
    end

    it "will clear its caches" do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing = XamplTestRedis::DroolingIdiotPersistedObject.new('test')

      redis.perm_cache(thing)
      redis.clear_cache
      found, target = redis.read_from_cache(thing.class, thing.get_the_index)

      found.should be_nil
      target.should be_nil
    end

    it 'will have weak cache references' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      thing_referenced = XamplTestRedis::DroolingIdiotPersistedObject.new('referenced')

      redis.perm_cache(thing_referenced)
      redis.perm_cache(XamplTestRedis::DroolingIdiotPersistedObject.new('unreferenced'))

      GC.start

      redis.read_from_cache(XamplTestRedis::DroolingIdiotPersistedObject, 'referenced').first.should == thing_referenced
      redis.read_from_cache(XamplTestRedis::DroolingIdiotPersistedObject, 'unreferenced').first.should be_nil
    end

    it 'two different objects are cached under the same key if the first is GCed' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis)

      redis.perm_cache(XamplTestRedis::DroolingIdiotPersistedObject.new('test'))
      GC.start
      redis.perm_cache(XamplTestRedis::DroolingIdiotPersistedObject.new('test'))
    end

    it 'will establish a redis connection to an unknown redis database' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis,
                                           :allow_connections => true,
                                           :connect_to_known => false,
                                           :connect_to_unknown => true)

      client = redis.client
      client.should be_an_instance_of(::Redis)

      repo_properties = redis.repo_properties
      repo_properties['name'].should == redis.name
      repo_properties['mentions'].should be_true
      repo_properties['created_at'].should_not be_nil
    end

    it 'will establish a redis connection to an known redis database' do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis1 = Xampl.create_named_persister(repo_name, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => false,
                                            :connect_to_unknown => true)

      client = redis1.client
      client.should be_an_instance_of(::Redis)

      repo_properties = redis1.repo_properties
      repo_properties['name'].should == redis1.name
      repo_properties['mentions'].should be_true
      repo_properties['created_at'].should_not be_nil

      Xampl.drop_persister(repo_name)

      redis2 = Xampl.create_named_persister(repo_name, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => false)

      client = redis2.client
      client.should be_an_instance_of(::Redis)
    end

    it 'will prevent connections to new repositories' do
      repo_name = XamplTestRedis.scratch_name('redis')
      lambda do
        Xampl.create_named_persister(repo_name, :redis,
                                     :allow_connections => true,
                                     :connect_to_known => true,
                                     :connect_to_unknown => false)
      end.should raise_exception(IncompatiblePersisterConfiguration)
    end

    it 'will prevent connections to existing repositories' do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis1 = Xampl.create_named_persister(repo_name, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => false,
                                            :connect_to_unknown => true)

      client = redis1.client
      client.should be_an_instance_of(::Redis)

      Xampl.drop_persister(repo_name)

      lambda do
        Xampl.create_named_persister(repo_name, :redis,
                                     :allow_connections => true,
                                     :connect_to_known => false,
                                     :connect_to_unknown => true)
      end.should raise_exception(IncompatiblePersisterConfiguration)
    end

    it "will connect to two different repositories in the same redis db" do
      redis1 = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis,
                                            :allow_connections => true,
                                            :connect_to_known => false,
                                            :connect_to_unknown => true)
      redis1.should_not be_nil
      redis2 = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis,
                                            :allow_connections => true,
                                            :connect_to_known => false,
                                            :connect_to_unknown => true)
      redis2.should_not be_nil
      redis2.should_not == redis1

      known_repos = redis1.known_repos
      known_repos.should include(redis1.repo_name, redis2.repo_name)
    end

    it "will only create one persister wiith a given name" do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis1 = Xampl.create_named_persister(repo_name, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => true)
      redis2 = Xampl.create_named_persister(repo_name, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => true)

      redis1.should == redis2
    end

    it 'will allow clobbering an entire redis database when clobbering is explicitly enabled' do
      repo_name1 = XamplTestRedis.scratch_name('redis')
      redis1 = Xampl.create_named_persister(repo_name1, :redis,
                                            :clobbering_allowed => true,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => true)
      repo_name2 = XamplTestRedis.scratch_name('redis')
      redis2 = Xampl.create_named_persister(repo_name2, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => true)

      known_repos = redis2.known_repos
      known_repos.should include(repo_name1, repo_name2)

      redis1_repo_properties_key = redis1.repo_properties_key
      redis1_repo_properties_key.should_not be_nil
      redis2.client.exists(redis1_repo_properties_key).should be_true

      # add some non-standard keys for this
      prefix = redis1.common_key_prefix
      extra1 = "#{ prefix }one"
      redis1.client.set(extra1, "one")
      extra2 = "#{ prefix }two"
      redis1.client.set(extra2, "two")
      extra3 = "#{ prefix }three"
      redis1.client.set(extra3, "three")

      redis2.client.get(extra1).should == "one"
      redis2.client.get(extra2).should == "two"
      redis2.client.get(extra3).should == "three"

      redis1.clobber

      known_repos = redis2.known_repos
      known_repos.should_not include(repo_name1)
      known_repos.should include(repo_name2)

      redis2.client.exists(redis1_repo_properties_key).should be_false

      redis2.client.get(extra1).should be_nil
      redis2.client.get(extra2).should be_nil
      redis2.client.get(extra3).should be_nil
    end

    it 'will *not* allow clobbering an entire redis database when clobbering is *not* explicitly enabled' do
      repo_name1 = XamplTestRedis.scratch_name('redis')
      redis1 = Xampl.create_named_persister(repo_name1, :redis,
                                            :allow_connections => true,
                                            :connect_to_known => true,
                                            :connect_to_unknown => true)

      lambda do
        redis1.clobber
      end.should raise_exception(IncompatiblePersisterConfiguration)
    end


    it 'will re-establish a redis connection' do
      redis = Xampl.create_named_persister(XamplTestRedis.scratch_name('redis'), :redis,
                                           :allow_connections => true,
                                           :connect_to_known => true,
                                           :connect_to_unknown => true)

      redis_client = redis.client
      redis_client.client.should be_connected

      redis.close

      redis_client.client.should_not be_connected

      redis_client.ping.should == "PONG" # this will reconnect
      redis_client.client.should be_connected
    end

    #TODO -- LOCKS!!!! on the db, BUT WAIT FOR THE NEW EXPIRE FUNCTIONALITY

  end

  describe 'redis reading and writing xampl objects' do
    before :each do
      Xampl.drop_all_persisters
      Xampl.set_default_persister_properties(:testing => true,
                                             :allow_connections => true,
                                             :connect_to_known => true,
                                             :connect_to_unknown => true)
    end
    after :each do
    end


    it "will write an xampl object" do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis = Xampl.create_named_persister(repo_name, :redis)

      redis_client = redis.client
      redis_client.client.should be_connected

      author_pid = 'anonymous'
      key = redis.key_for_class(RedisTest::Author, author_pid)

      redis.in_any_cache?(RedisTest::Author, author_pid).should be_false

      current_value = redis_client.get(key)
      current_value.should be_nil

      redis.in_any_cache?(RedisTest::Author, author_pid).should be_false

      author = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author.new(author_pid)

        redis.in_any_cache?(RedisTest::Author, author_pid).should be_true
        redis.in_new_cache?(RedisTest::Author, author_pid).should be_true
        redis.in_cache?(RedisTest::Author, author_pid).should be_false
      end

      mentions = []
      xml = redis.represent(author, mentions)

      current_value = redis_client.get(key)
      current_value.should == xml

      redis.in_any_cache?(RedisTest::Author, author_pid).should be_true
      redis.in_new_cache?(RedisTest::Author, author_pid).should be_false
      redis.in_cache?(RedisTest::Author, author_pid).should be_true

      GC.start

      redis.in_cache?(RedisTest::Author, author_pid).should be_true

      author = nil

      GC.start

      redis.in_cache?(RedisTest::Author, author_pid).should be_false

      # NOTE -- I don't know if this test passing is a good or bad thing. Seems to be contrary to how docs seem to explain weak_refs,
      #         on the other hand, it's what we need here. ??
    end

    it "will write a changed xampl object" do
      repo_name = XamplTestRedis.scratch_name('redis')
      redis = Xampl.create_named_persister(repo_name, :redis)
      redis_client = redis.client

      author_pid = 'anonymous'
      key = redis.key_for_class(RedisTest::Author, author_pid)

      author = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author.new(author_pid)
      end

      mentions = []
      xml1 = redis.represent(author, mentions)

      current_value = redis_client.get(key)
      current_value.should == xml1

      Xampl.transaction(repo_name) do
        author.info = 'changed'
        author.should be_dirty
      end
      author.should_not be_dirty

      mentions = []
      xml2 = redis.represent(author, mentions)

      xml2.should_not == xml1

      current_value = redis_client.get(key)
      current_value.should == xml2
    end

    it "will read a xampl object with different redis instances" do
      repo_name = XamplTestRedis.scratch_name('redis')
      Xampl.create_named_persister(repo_name, :redis)

      author_pid = 'anonymous'

      author_info = XamplTestRedis.scratch_name('author-info')
      author_object_id_original = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author.new(author_pid)
        author.info = author_info
        author_object_id_original = author.object_id
      end

      Xampl.drop_all_persisters
      GC.start # shouldn't make any difference, but do it anyway
      GC.start # shouldn't make any difference, but do it anyway
      GC.start # shouldn't make any difference, but do it anyway

      Xampl.create_named_persister(repo_name, :redis)

      author = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author[author_pid]
      end

      author.should_not be_nil
      author.info.should == author_info
      author.object_id.should_not == author_object_id_original
    end

    it "will read a xampl object from cache of same redis instance" do
      repo_name = XamplTestRedis.scratch_name('redis')
      Xampl.create_named_persister(repo_name, :redis)

      author_pid = 'anonymous'

      author_info = XamplTestRedis.scratch_name('author-info')
      author_object_id_original = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author.new(author_pid)
        author.info = author_info
        author_object_id_original = author.object_id
      end

      Xampl.create_named_persister(repo_name, :redis)

      author = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author[author_pid]
      end

      author.should_not be_nil
      author.info.should == author_info
      author.object_id.should == author_object_id_original
    end

    it "will read a xampl object flushed from the cache cache of same redis instance" do
      repo_name = XamplTestRedis.scratch_name('redis')
      Xampl.create_named_persister(repo_name, :redis)

      author_pid = 'anonymous'

      author_info = XamplTestRedis.scratch_name('author-info')
      author_object_id_original = nil
      Xampl.transaction(repo_name) do
        author = RedisTest::Author.new(author_pid)
        author.info = author_info
        author_object_id_original = author.object_id
      end

      #try this 10 times because the GC can't be counted on to have actually run
      10.times do
        author = nil

        # this should empty the weak-ref cache, but maybe not
        GC.start
        sleep(0.2)

        Xampl.create_named_persister(repo_name, :redis)

        Xampl.transaction(repo_name) do
          author = RedisTest::Author[author_pid]
        end

        next if author.object_id == author_object_id_original

        author.should_not be_nil
        author.info.should == author_info
        author.object_id.should_not == author_object_id_original
        break
      end
    end

#    it "will zzz" do
#      pending
#    end

#    it "will zzz" do
#      pending
#    end

#    it "will zzz" do
#      pending
#    end

  end

end
