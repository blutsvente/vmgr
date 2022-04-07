# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <tlemail69-github@yahoo.com>
# ---
module Vmgr
    #
    # Class representing test-container and its attributes
    #
    class TestContainer < Container

      def initialize(name)
          super(name, :test)
      end
    end

end
