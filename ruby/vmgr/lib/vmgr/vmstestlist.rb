# Ruby Vmgr (Vmanager) library
#
# Creation Date: May/2021
# Author: <thorsten.dworzak@verilab.com>
# ---
module Vmgr
    #
    # Class representing a VMS testlist
    #
    class VmsTestlist < Struct.new(:name, :handle)

      # Only commonly used options are contained in this hash, to make them appear
      # in the same order in the testlist; others are just concatenated w/o any
      # particular order.
      # vms-option => alias
      attr_accessor :standard_options

      @groups = Array.new()

      def initialize(_name, _handle)
         super(_name, _handle)
         @standard_options = {
            "sim_mode"   => "mode",
            "test_group" => "",
            "num_seeds"  => "count",
            "rand_seed"  => "",
            "sv_seed"    => "",
            "sim_args"   => "",
            "lsf_mem"    => "",
            "lsf_args"   => "",
            "lsf_queue"  => ""
         }
         @groups = Array.new()
      end

      def add_group_container(_group)
         @groups.push(_group)
      end

      def add_separator(text = "")
         handle.puts("")
         handle.puts("#")
         handle.puts("# #{text}")
         handle.puts("#")
      end

      def write()
         handle.puts("# Regression: #{name}")

         @groups.each { | group |
            last_group = ""

            # Iterate over all tests in the group, sorted by the test_group attribute
            # and print a row in the resulting file for each
            group.tests.sort_by { | test | test.get_value("test_group") }.each { | test |

               # Print a separator for each new group
               test_group = test.get_value("test_group")
               if test_group != last_group
                  add_separator("Test Group: #{test_group}")
                  last_group = test_group
               end

               # Extract all attributes for a row in vms_run format
               row = get_row_str(test)
               handle.puts row.join(" ")
            }
         }

         handle.puts("# end")
      end

      # Returns a string for one row (test name plus options)
      # Options in @standard_options list are put first
      def get_row_str(test)
         cols = Array.new()
         cols[0] = test.name
         test_work = test.clone()
         current_index = 1

         # Collect all standard options first
         @standard_options.each { | (option, alias_name) |
            if test_work.has_attribute(option)
               out_option = "-" + option
               out_value  = get_value_str(test_work, option) || ""
               test_work.delete_attribute(option)
            elsif alias_name != "" && test_work.has_attribute(alias_name)
               out_option = "-" + option
               out_value  = get_value_str(test_work, alias_name) || ""
               test_work.delete_attribute(alias_name)
            else
               next
            end

            cols[current_index] = out_option + " " + out_value
            current_index += 1
         }

         # Collect all remaining options
         test_work.hattribs.each_key { | option |
            out_option = "-" + option
            out_value  = get_value_str(test_work, option) || ""
            cols[current_index] = out_option + " " + out_value
            current_index += 1
         }

         return cols
      end

      # Returns a value correctly quoted
      def get_value_str(test, attrib)
         result = test.get_value(attrib)
         unless result == nil
            # strip the <text> tags
            result.gsub!(%r{</?text>}, "")
            # quote value if necessary
            if result =~ /\s/
               result = "' " + result + "'"
            end
         end

         return result
      end
    end

end
