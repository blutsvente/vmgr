# Ruby Vmgr (Vmanager) library
#
# Creation Date: May/2021
# Author: <tlemail69-github@yahoo.com>
# ---
module Vmgr
    #
    # Class representing a VMS testlist
    #
    class VmsTestlist < Struct.new(:name, :handle)

      # Options from the source .vsif are first searched for in the standard_options hash.
      # Only commonly used options are in this hash, to make them appear
      # in the same order in the testlist; others are just concatenated w/o any
      # particular order. They can also be renamed (hash key -> value mapping)
      # Filtering can be done via filter_options hash (to remove unwanted options)
      # vms-option => alias
      attr_accessor :standard_options
      attr_accessor :filter_options

      def initialize(_name, _handle)
         super(_name, _handle)
         @standard_options = {
            "sim_mode"   => "mode",
            "test_group" => "",
            "num_seeds"  => "count",
            "rand_seed"  => "",
            "sv_seed"    => "seed",
            "sim_args"   => "",
            "lsf_mem"    => "",
            "lsf_args"   => "",
            "lsf_queue"  => ""
         }
         @filter_options = [
            "sanity_count",
            "sanity_seed"
         ]
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
         current_index = 0
         cols[current_index] = test.name
         current_index += 1
         test_work = test.clone()
         out_options = Hash.new()

         # Collect all standard options first, apply aliasing
         @standard_options.each { | (option, alias_name) |
            if test_work.has_attribute(option)
               out_options[option] = get_value_str(test_work, option) || ""
               test_work.delete_attribute(option)
            end
            if alias_name != "" && test_work.has_attribute(alias_name)
               out_options[option] = get_value_str(test_work, alias_name) || ""
               test_work.delete_attribute(alias_name)
            else
               next
            end
         }

         # Dump options in cols array
         out_options.each { | (option, value) |
            cols[current_index] = "-" + option + " " + value
            current_index += 1
         }

         # Collect all remaining options, filtering out any unwanted ones
         test_work.hattribs.each_key { | option |
            next if @filter_options.find_index(option) != nil
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
            # quote value in vms_run-style if necessary
            if result =~ /\s/
               result = "' " + result + "'"
            end
         end

         return result
      end
    end

end
