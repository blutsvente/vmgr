# Ruby Vmgr (Vmanager) library
#
# Creation Date: MAR/2020
# Author: <tlemail69-github@yahoo.com>
# ---
module Vmgr
    #
    # Class representing group-container and its attributes; a group can contain
    # tests or other groups
    class GroupContainer < Container

      def initialize(name)
          super(name, :group)
          @hattribs = { "groups" => [],
                        "tests" => [] }
          @valid_list_attributes.push("groups", "tests")
      end

      # Add add_ and find_ methods for allowed list attributes
      add_list_attribute_accessors("group")
      add_list_attribute_accessors("test")

      # Override the base-class method
      def write(handle, indent=0)
          handle.puts INDENT * indent + "#{ctype.to_s} #{name} {"
          @hattribs.each { |key, value|
            if @valid_list_attributes.include?(key) then
                @hattribs[key].each { |hcontainer|
                  hcontainer.write(handle, indent + 1)
                }
            else
                handle.puts INDENT * (indent + 1) + "#{key}: #{value};"
            end
          }
          handle.puts INDENT * indent + "};"
      end
    end
end
