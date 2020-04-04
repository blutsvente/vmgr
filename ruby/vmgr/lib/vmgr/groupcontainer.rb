# Ruby Vmgr (Vmanager) library
#
# Creation Date: MAR/2020
# Author: <thorsten.dworzak@verilab.com

module Vmgr
   #
   # Struct representing group-container and its attributes; a group can contain
   # tests or other groups
   # Just add more to the struct constructor call if required.
   #

    class GroupContainer< Struct.new(:name, :groups, :tests)

      # Setter/getter for container attributes
      def method_missing(name, *args, &block)
         if name =~ /^(\w+)=$/ then
            return self.instance_variable_set("@#{$1}", *args)
         elsif name =~ /^(\w+)$/ then
            return self.instance_variable_get("@#{$1}")
         end
         super
      end

      def write(handle, indent=0)
        handle.puts "   " * indent + "group #{name} {"
        self.instance_variables.each {|member|
            case member
            when :@name
              next
            when :@groups, :@tests
               instance_variable_get(member).each { |it| it.write(handle, indent + 1) }
            else
              if defined?(v = instance_variable_get(member)) then
                handle.puts "   " * (indent + 1) + "#{member}".sub(/^@/, '') + ": #{v};"
              end
            end
        }
        handle.puts "   " * indent + "};"
      end
   end
end
