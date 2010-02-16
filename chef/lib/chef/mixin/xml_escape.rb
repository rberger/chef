#
# Author:: Sam Ruby
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
# Copyright:: Copyright (c) 2005 Sam Ruby
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Code adapted from Sam Ruby's xchar.rb http://intertwingly.net/stories/2005/09/28/xchar.rb
# Thanks, Sam!

class Chef
  module Mixin
    module XMLEscape
      extend self

      CP1252 = {
        128 => 8364, # euro sign
        130 => 8218, # single low-9 quotation mark
        131 =>  402, # latin small letter f with hook
        132 => 8222, # double low-9 quotation mark
        133 => 8230, # horizontal ellipsis
        134 => 8224, # dagger
        135 => 8225, # double dagger
        136 =>  710, # modifier letter circumflex accent
        137 => 8240, # per mille sign
        138 =>  352, # latin capital letter s with caron
        139 => 8249, # single left-pointing angle quotation mark
        140 =>  338, # latin capital ligature oe
        142 =>  381, # latin capital letter z with caron
        145 => 8216, # left single quotation mark
        146 => 8217, # right single quotation mark
        147 => 8220, # left double quotation mark
        148 => 8221, # right double quotation mark
        149 => 8226, # bullet
        150 => 8211, # en dash
        151 => 8212, # em dash
        152 =>  732, # small tilde
        153 => 8482, # trade mark sign
        154 =>  353, # latin small letter s with caron
        155 => 8250, # single right-pointing angle quotation mark
        156 =>  339, # latin small ligature oe
        158 =>  382, # latin small letter z with caron
        159 =>  376 # latin capital letter y with diaeresis
      } unless defined?(CP1252)

      # http://www.w3.org/TR/REC-xml/#dt-chardata
      PREDEFINED = {
        38 => '&amp;', # ampersand
        60 => '&lt;',  # left angle bracket
        62 => '&gt;'  # right angle bracket
      } unless defined?(PREDEFINED)

      # http://www.w3.org/TR/REC-xml/#charsets
      VALID = [[0x9, 0xA, 0xD], (0x20..0xD7FF), 
        (0xE000..0xFFFD), (0x10000..0x10FFFF)] unless defined?(VALID)

      def xml_escape(unescaped_str)
        begin
          unescaped_str.unpack("U*").map {|char| xml_escape_char!(char)}.join
        rescue
          unescaped_str.unpack("C*").map {|char| xml_escape_char!(char)}.join
        end
      end

      private

      def xml_escape_char!(char)
        char = CP1252[char] || char
        char = 42 unless VALID.detect {|range| range.include? char}
        char = PREDEFINED[char] || (char<128 ? char.chr : "&##{char};")
      end

    end
  end
end
