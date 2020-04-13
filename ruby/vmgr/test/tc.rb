#!/usr/bin/env ruby
require_relative "../lib/vmgr/container.rb"
require_relative "../lib/vmgr/sessioncontainer.rb"
c = Vmgr::SessionContainer.new("bla", "this is a description")
puts c

c.attr1=[1,2,3]
c.attr2="bar"
c.count=3141

puts c.hattribs
puts c.attr1
puts c.attr2
puts c.name
puts c.count
c.write(STDOUT)
