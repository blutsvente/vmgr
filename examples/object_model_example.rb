#!/tools/apps/ruby/bin/ruby.2.1.5 -w
#
# Ruby Vmgr (Vmanager) library
#
# Example for creating a .vsif file using the object model
# ---
# Author: Thorsten Dworzak <tlemail69-github@yahoo.com>
# ---
#

require_relative '../lib/vmgr/collaterals.rb'
require_relative '../lib/vmgr/container.rb'
require_relative '../lib/vmgr/testcontainer.rb'
require_relative '../lib/vmgr/groupcontainer.rb'
require_relative '../lib/vmgr/sessioncontainer.rb'
require_relative '../lib/vmgr/session.rb'


module Vmgr

   # Build .vsif from the bottom up

   # Create test, group and link them
   @test_1 = TestContainer.new("test_one")
   @test_1.add_attribute("count", 10)
   @test_1.add_attribute("maxruntime", 1800)

   @group_1 = GroupContainer.new("group_1")
   @group_1.add_attribute("sim_mode", "RTL")
   @group_1.add_test(@test_1)

   # Create two more tests and a new group and link them
   @test_2 = TestContainer.new("test_two")
   @test_2.add_attribute("sv_seed", 12535343)
   @test_3 = TestContainer.new("test_three")
   @test_3.add_attribute("sim_args","+DISABLE_SB +RUNS=6")

   @group_2 = GroupContainer.new("group_2")
   @group_2.add_test(@test_2)
   @group_2.add_test(@test_3)
   @group_2.add_attribute("sim_mode", "CORE")
   @group_2.add_attribute("count", 100)

   # Create a new group and link the two groups created earlier
   @group_top = GroupContainer.new("group_top")
   @group_top.add_group(@group_1)
   @group_top.add_group(@group_2)

   # Create session container with global default values and link the group_top
   @session_container = SessionContainer.new("demo", "object_model_example - .vsif generation", :vsif)
   @session_container.add_attribute("sv_seed", "random")
   @session_container.add_attribute("count", 1)
   @session_container.add_attribute("maxruntime", 600)
   @session_container.add_group(@group_top)

   # Create a session and set its session_container to the one created above
   @session = Session.new("session demo")
   @session.session_container = @session_container

   # Last step: render the .vsif file
   @session.write_vsif("object_model_example.vsif")

end