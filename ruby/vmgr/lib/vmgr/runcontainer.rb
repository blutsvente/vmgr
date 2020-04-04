# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <thorste.dworzak@verilab.com

module Vmgr
   #
   # Struct representing only the interesting run-container attributes
   # Just add more to the struct constructor call if required.
   #
   class RunContainer < Struct.new(:test_name, :seed, :simulation_time)
      def method_missing(name, *args, &block)
         # puts "ignored #{name}"
      end
   end
end
