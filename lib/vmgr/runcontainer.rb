# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <tlemail69-github@yahoo.com
# ---
module Vmgr
    #
    # Class representing the run-container of .vsof files
    #
    class RunContainer < Container # Struct.new(:test_name, :seed, :simulation_time)

      def initialize(name)
          super(name, :run)
      end
    end
end
