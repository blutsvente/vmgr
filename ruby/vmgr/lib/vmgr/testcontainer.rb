# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <thorsten.dworzak@verilab.com

module Vmgr
   #
   # Struct representing test-container and its attributes
   # Just add more to the struct constructor call if required.
   #
   class TestContainer < Struct.new(:test_name, :seed, :count, :top_files)

      # Setter/getter for container attributes
      def method_missing(name, *args, &block)
         if name =~ /^(\w+)=$/ then
            return self.instance_variable_set("@#{$1}", *args)
         elsif name =~ /^(\w+)$/ then
            return self.instance_variable_get("@#{$1}", *args)
         end
         super
      end

      def write(handle, indent)
         handle.puts "   " * indent + "group #{test_name} {"
         self.instance_variables.each {|member|
            case member
            when :@test_name
              next
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
