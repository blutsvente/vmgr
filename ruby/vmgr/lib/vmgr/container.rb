# Ruby Vmgr (Vmanager) library
#
# Creation Date: APR/2020
# Author: <thorsten.dworzak@verilab.com
# ---
# Base class for vsif/vsof container
module Vmgr
    #
    # Base class representing any type (:ctype) of vsif/vsof containers
    #
    class Container

      attr_accessor :name
      attr_reader   :ctype
      attr_accessor :hattribs
      attr_reader   :INDENT

      # Constructor
      def initialize(_name, _ctype)
          @@INDENT = "   "
          @hattribs = {}
          @name = _name
          @ctype = _ctype
      end

      # Create accessor for getting attributes
      def method_missing(_name, *args, &block)
          if _name =~ /^(\w+)=$/ then
            return @hattribs[$1] = (args.size > 1 ? args: args[0])
          elsif _name =~ /^(\w+)$/ then
            return @hattribs.has_key?($1) ? @hattribs[$1] : super
          end
          super
      end

      # General accessor to add/override an attribute
      def add_attribute(key, value)
          @hattribs[key] = value
      end

      # Delete an attribute
      def delete_attribute(key)
          @hattribs.delete(key)
      end

      # Check whether attribute exists
      def has_attribute(_name)
          return @hattribs.has_key?(_name)
      end

      # Use macros to create accessor methods for list attributes
      # of the form:
      # add_<name-of-list-attribute> (container)
      # find_<name-of-list-attribute>(name)
      def self.add_list_attribute_accessors(what)
          define_method("find_#{what}") do |_name|
            if @hattribs.has_key?("#{what}s")
                idx = @hattribs["#{what}s"].rindex{|item| item.name == _name}
                return @hattribs["#{what}s"][idx] if idx != nil
            end
            return nil
          end

          define_method("add_#{what}") do |val|
            if not self.send("find_#{what}", val.name) then
                @hattribs["#{what}s"].push(val)
            end
          end
      end

      # Write (scalar) attributes to handle
      def write(handle, indent=0)
          handle.puts @@INDENT * indent + "#{ctype.to_s} #{name} {"
          @hattribs.each { |key, value|
            handle.puts @@INDENT * (indent + 1) + "#{key}: #{value};"
          }
          handle.puts @@INDENT * indent + "};"
      end
    end
end
