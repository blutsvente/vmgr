# Ruby Vmgr (Vmanager) library
#
# Creation Date: APR/2020
# Author: <thorsten.dworzak@verilab.com>
# ---
module Vmgr
    #
    # Class representing a session container
    #
    class SessionContainer < Container

      attr_reader :description
      attr_reader :kind

      # Add add_ and find_ methods for allowed list attributes
      add_list_attribute_accessors("group")
      add_list_attribute_accessors("run")

      def initialize(_name, _description, _kind = "")
          super(_name, :session)
          @description = _description
          @hattribs = { "groups" => [],
                      "runs" => [] }
          @kind = _kind
      end

      # Write content to file handle
      def write(handle, indent=0)
          handle.puts "// #{@description}"
          handle.puts @@INDENT * indent + "#{ctype.to_s} #{name} {"
          @hattribs.each { |key, value|
            next if ["groups","tests"].include?(key)
            next if kind == :vsif and key == "runs"
            next if kind == :vsof and key == "groups"
            handle.puts @@INDENT * (indent + 1) + "#{key}: #{value};"
          }
          handle.puts @@INDENT * indent + "};"

          # write the groups
          @hattribs["groups"].each {|it|
            it.write(handle, indent)
          }
      end
    end
end
