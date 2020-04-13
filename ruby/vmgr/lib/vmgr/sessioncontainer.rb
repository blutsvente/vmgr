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

      # Attributes to ignore for flatten_groups()
      FLATTEN_IGNORE_ATTRIBS = ["runs", "session_description"]

      # Add add_ and find_ methods for allowed list attributes
      add_list_attribute_accessors("group")
      add_list_attribute_accessors("run")

      def initialize(_name, _description, _kind = "")
          super(_name, :session)
          @description = _description
          @hattribs = { "groups" => [],
                      "runs" => [] }
          @kind = _kind
          @valid_list_attributes.push("groups", "runs")
      end

      # Write content to file handle
      def write(handle, indent=0)
          handle.puts "// #{@description}"
          handle.puts INDENT * indent + "#{ctype.to_s} #{name} {"
          @hattribs.each { |key, value|
            next if ["groups","tests"].include?(key)
            next if kind == :vsif and key == "runs"
            next if kind == :vsof and key == "groups"
            handle.puts INDENT * (indent + 1) + "#{key}: #{value};"
          }
          handle.puts INDENT * indent + "};"

          if kind == :vsif then
            # write the groups
            @hattribs["groups"].each {|it|
                it.write(handle, indent)
            }
          elsif kind == :vsof then
            # write run-containers
            @hattribs["runs"].each {|it|
                it.write(handle, indent)
            }
          end
      end

      # Write content in vms_run testlist format to file handle
      def write_tl(handle)
        handle.puts "# #{@description}"
        if not self.has_attribute("groups")
          STDERR.puts "#{ME} [WARNING]: Session #{self.name} has no groups, nothing to be done"
          return
        end

        testlist = VmsTestlist.new(self.name, handle)

        self.groups.each { |group|
          if not group.has_attribute("tests")
            STDERR.puts "#{ME} [WARNING]: Group #{group.name} has no tests, nothing to be done"
          else
            testlist.add_group_container(group)
          end
        }

        testlist.write();
      end

      # Return a new container with groups flattened, i.e. only one group "flat"
      # and all group attributes copied to tests
      def flatten_groups(flat_group_name)
        new_session = SessionContainer.new(self.name, self.description, :vsif)
        flat_group = GroupContainer.new(flat_group_name)

        flatten_groups_core(flat_group, self, "")
        new_session.add_group(flat_group)
        return new_session
      end

      def flatten_groups_core(_flat_group, _container, _parent_group_name, _test_attribs = {})

        # Collect scalar attributes
        scalar_attribs = _container.hattribs.select { |find_key, |
          !_container.valid_list_attributes.include?(find_key) && !FLATTEN_IGNORE_ATTRIBS.include?(find_key)
        }

        # extract vms test-group attribute from group name; we will concatenate the .vsif group names
        # to make them unique because vms groups cannot be nested
        test_group = ""
        if _container.ctype == :group
          if _parent_group_name == ""
            test_group = _container.name
          else
            test_group = [_parent_group_name, _container.name].join("_")
          end
          scalar_attribs["test_group"] = test_group
        end

        # scalar_attribs.each { |key, value|
        #    print "#{_container.name} #{key} #{value}\n"
        # }

        # Iterate over list attributes and recursively call this function until there is no more hierarchy
        list_attribs = _container.hattribs.keys.select { |find_key, | _container.valid_list_attributes.include?(find_key)}
        list_attribs.each { |list_attrib |
          if !FLATTEN_IGNORE_ATTRIBS.include?(list_attrib)
            # puts "list #{list_attrib} size #{_container.hattribs[list_attrib].size}"
            _container.hattribs[list_attrib].each { |child_container|
              case child_container.ctype
              when :group
                flatten_groups_core(_flat_group, child_container, test_group, _test_attribs.merge(scalar_attribs))
              when :test
                 flatten_groups_core(_flat_group, child_container, test_group, _test_attribs.merge(scalar_attribs))
              end
            }
          end
        }

        # Add collected attributes to test, and test to resulting flat group
        if _container.ctype == :test
          new_test = TestContainer.new(_container.name)
          new_test.hattribs = _test_attribs.merge(scalar_attribs)
          _flat_group.add_test(new_test)
        end

      end

    end # class
end # module
