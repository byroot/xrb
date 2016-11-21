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

require_relative 'buffer'
require 'strscan'

module Trenni
	class StringScanner < ::StringScanner
		def initialize(buffer)
			@buffer = buffer
			
			super(buffer.read)
		end
		
		attr :buffer
		
		def path
			@buffer.path
		end
		
		STUCK_MESSAGE = "Parser is stuck!".freeze
		
		def stuck?(position)
			self.pos == position
		end
			
		def raise_if_stuck(position, message = STUCK_MESSAGE)
			if stuck?(position)
				parse_error!(message)
			end
		end
		
		def parse_error!(message, positions = nil)
			positions ||= [self.pos]
			
			raise ParseError.new(message, @buffer, positions.first)
		end
	end
end
