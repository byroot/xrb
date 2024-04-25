# frozen_string_literal: true

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Trenni
	module Strings
		HTML_ESCAPE = {"&" => "&amp;", "<" => "&lt;", ">" => "&gt;", "\"" => "&quot;"}
		HTML_ESCAPE_PATTERN = Regexp.new("[" + Regexp.quote(HTML_ESCAPE.keys.join) + "]")

		def self.to_html(string)
			string.gsub(HTML_ESCAPE_PATTERN){|c| HTML_ESCAPE[c]}
		end

		def self.to_quoted_string(string)
			string = string.gsub('"', '\\"')
			string.gsub!(/\r/, "\\r")
			string.gsub!(/\n/, "\\n")
			
			return "\"#{string}\""
		end
		
		# `value` must already be escaped.
		def self.to_attribute(key, value)
			%Q{#{key}="#{value}"}
		end
		
		def self.to_simple_attribute(key, strict)
			strict ? %Q{#{key}="#{key}"} : key.to_s
		end
		
		def self.to_title(string)
			string = string.gsub(/(^|[ \-_])(.)/){" " + $2.upcase}
			string.strip!
			
			return string
		end
		
		def self.to_snake(string)
			string = string.gsub("::", "")
			string.gsub!(/([A-Z]+)/){"_" + $1.downcase}
			string.sub!(/^_+/, "")
			
			return string
		end
	end
end