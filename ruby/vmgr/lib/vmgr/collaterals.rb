# Ruby Vmgr (Vmanager) library
#
# Creation Date: AUG/2019
# Author: <thorsten.dworzak@verilab.com>

module Vmgr

   # helper methods in String class
   class ::String
      def sizeup(max_len=80)
         return (max_len>15 and size>max_len) ? self[0..max_len/10]+"[...]"+self[-(max_len-max_len/10-6)..-1] : self
      end

      def red; "\e[31m#{self}\e[0m" end
   end
end
