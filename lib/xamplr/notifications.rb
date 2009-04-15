#!/usr/bin/env ruby

module Xampl
  module XamplObject

    # add text (while loading from XML)
    #   xml_text -- the text
    #   realising -- true when loading from a persister
    def note_adding_text_content(xml_text, realising)
      return xml_text
    end

    # these are the arrays of attribute information about to be used to
    # initialise the attributes

    def note_initialise_attributes_with(names, namespaces, values, realising)
    end

    # attributes are setup up (while loading from XML)

    def note_attributes_initialised(realising)
    end

    # just created

    def note_created(realising)
    end

    # about to be added to a parent

    def note_add_to_parent(parent, realising)
      return self
    end

    # about to be added to a parent

    def note_add_child(child, realising)
      return child
    end

    # this element has been completed

    def note_closed(realising)
      return self
    end

    # replacing the original

    def note_replacing(original)
    end

    # about to be invalidated

    def note_invalidate
    end
  end
end
