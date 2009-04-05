module TokyoCabinetExperimental

  require "xampl"
	include Xampl


  XamplObject.ns_preferred_prefix("http://xampl.com/tcx", "tcx")

  module PeopleAsChild
    require "indexed-array"
  
    def people_child
      accessed
      @people_child
    end

    def people_child=(v)
      accessed
      @people_child = v
    end

    alias people people_child
    alias people= people_child=
  
    def init_people_as_child
      @people_child = IndexedArray.new
    end
  
    def add_people(people)
      accessed
      index = people.get_the_index
      if(nil == index) then
        raise XamplException.new("no value for the index 'pid' of people defined in : " << people.pp_xml)
      end

      existing = @people_child[index]

      return existing if existing == people

			self.remove_people(index) if existing

      @children << people
      @people_child[index] = people

      people.add_parent(self)

      changed
      return people
    end
  
    def new_people(index)
      accessed

      people = nil
      people = People.lookup(index) if Xampl.persister and Xampl.persister.automatic
      people = People.new(index) unless people

      yield(people) if block_given?
      return add_people(people)
    end

    def ensure_people(index)
      accessed

      people = @people_child[index]
		  return people if people 

      people = People.lookup(index) if Xampl.persister and Xampl.persister.automatic
      people = People.new(index) unless people

      yield(people) if block_given?
      return add_people(people)
		end

    def remove_people(index)
      accessed
			changed
	    unless String === index or Symbol === index then
        index = index.get_the_index
			end
      people = @people_child.delete(index) if index
      @children.delete(people)
    end
  end

  module PersonAsChild
    require "indexed-array"
  
    def person_child
      accessed
      @person_child
    end

    def person_child=(v)
      accessed
      @person_child = v
    end

    alias person person_child
    alias person= person_child=
  
    def init_person_as_child
      @person_child = IndexedArray.new
    end
  
    def add_person(person)
      accessed
      index = person.get_the_index
      if(nil == index) then
        raise XamplException.new("no value for the index 'pid' of person defined in : " << person.pp_xml)
      end

      existing = @person_child[index]

      return existing if existing == person

			self.remove_person(index) if existing

      @children << person
      @person_child[index] = person

      person.add_parent(self)

      changed
      return person
    end
  
    def new_person(index)
      accessed

      person = nil
      person = Person.lookup(index) if Xampl.persister and Xampl.persister.automatic
      person = Person.new(index) unless person

      yield(person) if block_given?
      return add_person(person)
    end

    def ensure_person(index)
      accessed

      person = @person_child[index]
		  return person if person 

      person = Person.lookup(index) if Xampl.persister and Xampl.persister.automatic
      person = Person.new(index) unless person

      yield(person) if block_given?
      return add_person(person)
		end

    def remove_person(index)
      accessed
			changed
	    unless String === index or Symbol === index then
        index = index.get_the_index
			end
      person = @person_child.delete(index) if index
      @children.delete(person)
    end
  end

  class People
    include Xampl::XamplPersistedObject
  
    @@default_persister_format = nil

    def default_persister_format
      @@default_persister_format
    end
    def People.default_persister_format
      @@default_persister_format
    end
    def People.set_default_persister_format(format)
      @@default_persister_format = format
    end

    include Xampl::XamplWithDataContent

    @@tag = "people"
    @@ns = "http://xampl.com/tcx"
    @@ns_tag = "{http://xampl.com/tcx}people"
    @@module_name = "TokyoCabinetExperimental"
    @@safe_name = "TokyoCabinetExperimental_people"
    @@attributes = [
                     [ :@pid, "pid" ],
                   ]
    include TokyoCabinetExperimental::PersonAsChild

    @@to_yaml_properties = [ "@pid" ]
    @@to_yaml_properties_all = [
                                 "@pid",
                                 "@children",
                                 "@_content"
                               ] 

    def to_yaml_properties
      if is_yaml_root(self) then
        return @@to_yaml_properties_all
      else
        return @@to_yaml_properties
      end
    end

    def People.lookup(pid)
      Xampl.lookup(People, pid)
    end

    def People.[](pid)
      Xampl.lookup(People, pid)
    end

    def pid
      @pid
    end

    def pid=(v)
      accessed
			# This is kind of optimistic, I think you are in trouble if you do this
      Xampl.auto_uncache(self) if @pid
      @pid = v
      changed
      Xampl.auto_cache(self) if v
    end

    def initialize(index=nil)
      @pid = index if index
      super()

      @pid = nil if not defined? @pid

      init_xampl_object
      init_data_content
      init_person_as_child
  
      yield(self) if block_given?
      init_hook

      changed
    end

    def clear_non_persistent_index_attributes
    end
  
    def append_to(other)
      other.add_people(self)
    end
  
    def People.persisted?
      return :pid
    end

    def persisted?
      return :pid
    end

    def People.tag
      @@tag
    end
  
    def People.ns
      @@ns
    end
  
    def People.ns_tag
      @@ns_tag
    end

    def People.safe_name
      @@safe_name
    end
  
    def People.module_name
      @@module_name
    end
  
    def tag
      @@tag
    end
  
    def ns
      @@ns
    end
  
    def ns_tag
      @@ns_tag
    end

    def safe_name
      @@safe_name
    end
  
    def module_name
      @@module_name
    end
  
    def attributes
      @@attributes
    end
  
    def indexed_by
      :pid
    end
  
    def get_the_index
      @pid
    end
  
    def set_the_index(index)
      @pid = index
    end
   
    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_people(self) || self
    end
   
    def before_visit(visitor)
      visitor.before_visit_people(self)
    end
   
    def visit(visitor)
      visitor.visit_people(self)
    end
   
    def after_visit(visitor)
      visitor.after_visit_people(self)
    end

    Xampl::FromXML::register(People::tag, People::ns_tag, People)
  end

  class Person
    include Xampl::XamplPersistedObject
  
    @@default_persister_format = nil

    def default_persister_format
      @@default_persister_format
    end
    def Person.default_persister_format
      @@default_persister_format
    end
    def Person.set_default_persister_format(format)
      @@default_persister_format = format
    end

    include Xampl::XamplWithoutContent
  
    @@tag = "person"
    @@ns = "http://xampl.com/tcx"
    @@ns_tag = "{http://xampl.com/tcx}person"
    @@module_name = "TokyoCabinetExperimental"
    @@safe_name = "TokyoCabinetExperimental_person"
    @@attributes = [
                     [ :@pid, "pid" ],
                     [ :@name, "name" ],
                     [ :@age, "age" ],
                   ]

    @@to_yaml_properties = [ "@pid" ]
    @@to_yaml_properties_all = [ 

                                 "@pid",
                                 "@name",
                                 "@age",
                               ] 
  
    def to_yaml_properties
      if is_yaml_root(self) then
        return @@to_yaml_properties_all
      else
        return @@to_yaml_properties
      end
    end

    def Person.lookup(pid)
      Xampl.lookup(Person, pid)
    end

    def Person.[](pid)
      Xampl.lookup(Person, pid)
    end

    def pid
      @pid
    end

    def xxxpid=(v)
      accessed
			# This is kind of optimistic, I think you are in trouble if you do this
      Xampl.auto_uncache(self) if @pid
      @pid = v
      changed
      Xampl.auto_cache(self) if v
    end

    def pid=(v)
      accessed
			# This is kind of optimistic, I think you are in trouble if you do this
      Xampl.auto_uncache(self) if @pid
      @pid = v
      changed
      Xampl.auto_cache(self) if v
    end

    def name
      accessed
      @name
    end

    def name=(v)
      accessed
      changed
      @name = v
    end

    def age
      accessed
      @age
    end

    def age=(v)
      accessed
      changed
      @age = v
    end

    def initialize(index=nil)
      @pid = index if index
      super()

      @pid = nil if not defined? @pid
      @name = nil if not defined? @name
      @age = nil if not defined? @age

      init_xampl_object

      yield(self) if block_given?
      init_hook

      changed
    end
  
    def clear_non_persistent_index_attributes
      @name = nil
      @age = nil
    end
  
    def append_to(other)
      other.add_person(self)
    end
  
    def Person.persisted?
      return :pid
    end

    def persisted?
      return :pid
    end

    def Person.tag
      @@tag
    end
  
    def Person.ns
      @@ns
    end
  
    def Person.ns_tag
      @@ns_tag
    end

    def Person.safe_name
      @@safe_name
    end
  
    def Person.module_name
      @@module_name
    end
  
    def tag
      @@tag
    end
  
    def ns
      @@ns
    end
  
    def ns_tag
      @@ns_tag
    end

    def safe_name
      @@safe_name
    end
  
    def module_name
      @@module_name
    end
  
    def attributes
      @@attributes
    end

    def indexed_by
      :pid
    end
  
    def get_the_index
      @pid
    end
  
    def set_the_index(index)
      @pid = index
    end

    def substitute_in_visit(visitor)
      return visitor.substitute_in_visit_person(self) || self
    end
   
    def before_visit(visitor)
      visitor.before_visit_person(self)
    end
   
    def visit(visitor)
      visitor.visit_person(self)
    end
   
    def after_visit(visitor)
      visitor.after_visit_person(self)
    end

    Xampl::FromXML::register(Person::tag, Person::ns_tag, Person)
  end

end
