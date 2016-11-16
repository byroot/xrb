#!/usr/bin/env ruby

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

require 'trenni/parser'
require 'yaml'

RSpec.shared_context "valid markup" do
	let(:delegate) {Trenni::ParserDelegate.new}
	let(:buffer) {Trenni::Buffer(subject)}
	let(:parser) {Trenni::Parser.new(buffer, delegate)}
	let(:events) {parser.parse!; delegate.events}
	
	it "should parse without error" do
		expect{events}.to_not raise_error
	end
end

RSpec.describe "<br/>" do
	include_context "valid markup"
	
	it "should parse self-closing tag" do
		expect(events).to be == [
			[:begin_tag, "br", :opened],
			[:finish_tag, :opened, :closed],
		]
	end
end

RSpec.describe "<!DOCTYPE html>" do
	include_context "valid markup"
	
	it "should parse doctype" do
		expect(events).to be == [
			[:doctype, "html"]
		]
	end
end

RSpec.describe "<?foo=bar?>" do
	include_context "valid markup"
	
	it "should parse instruction" do
		expect(events).to be == [
			[:instruction, "foo=bar"]
		]
	end
end

RSpec.describe %Q{<!--comment-->} do
	include_context "valid markup"
	
	it "should parse comment" do
		expect(events).to be == [
			[:comment, "comment"]
		]
	end
end

RSpec.describe "<tag key=\"A&amp;B\" />" do
	include_context "valid markup"
	
	it "should parse escaped attributes" do
		expect(events).to be == [
			[:begin_tag, "tag", :opened],
			# TODO: What is the expected output here?
			# will content be double escape when output?
			[:attribute, "key", "A&amp;B"],
			[:finish_tag, :opened, :closed]
		]
	end
end

RSpec.describe "<foo bar=\"20\" baz>Hello World</foo>" do
	include_context "valid markup"
	
	it "should parse tag with content" do
		expect(events).to be == [
			[:begin_tag, "foo", :opened],
			[:attribute, "bar", "20"],
			[:attribute, "baz", true],
			[:finish_tag, :opened, :opened],
			[:text, "Hello World"],
			[:begin_tag, "foo", :closed],
			[:finish_tag, :closed, :opened],
		]
	end
end

RSpec.describe "<test><![CDATA[Hello World]]></test>" do
	include_context "valid markup"
	
	it "should parse CDATA" do
		expect(events).to be == [
			[:begin_tag, "test", :opened],
			[:finish_tag, :opened, :opened],
			[:cdata, "Hello World"],
			[:begin_tag, "test", :closed],
			[:finish_tag, :closed, :opened],
		]
	end
end

RSpec.describe "<foo bar=\"\" baz>" do
	include_context "valid markup"
	
	it "should parse empty attributes" do
		expect(events).to be == [
			[:begin_tag, "foo", :opened],
			[:attribute, "bar", ""],
			[:attribute, "baz", true],
			[:finish_tag, :opened, :opened],
		]
	end
end

RSpec.shared_examples "valid markup file" do |base|
	let(:xhtml_path) {File.join(__dir__, base + '.xhtml')}
	let(:events_path) {File.join(__dir__, base + '.rb')}
	
	subject {Trenni::FileBuffer.new(xhtml_path)}
	let(:expected_events) {eval(File.read(events_path), nil, events_path)}
	
	include_context "valid markup"
	
	def dump_events!
		File.open(events_path, "w+") do |output|
			output.puts "["
			events.each do |event|
				output.puts "\t#{event.inspect},"
			end
			output.puts "]"
		end
	end
	
	it "should match events" do
		# dump_events!
		
		expect(events).to be == expected_events
	end
end

RSpec.describe "performance_spec/large" do
	it_behaves_like "valid markup file", description
end

RSpec.shared_context "invalid markup" do
	let(:delegate) {Trenni::ParserDelegate.new}
	let(:buffer) {Trenni::Buffer.new(subject)}
	let(:parser) {Trenni::Parser.new(buffer, delegate)}
	let(:events) {parser.parse!; delegate.events}
	
	it "should fail to parse" do
		expect{events}.to raise_error Trenni::ParseError
	end
end

RSpec.describe "<foo" do
	include_context "invalid markup"
end

RSpec.describe "<foo bar=>" do
	include_context "invalid markup"
end

RSpec.describe "<p>\nこんにちは\nWorld\n<p" do
	include_context "invalid markup"

	let(:error) {events rescue $!}
	
	it "should fail on line 4" do
		expect(error.location.line_number).to be == 4
	end
	
	it "should fail at offset 2" do
		expect(error.location.line_offset).to be == 2
	end
end

RSpec.describe Trenni::Location do
	subject{described_class.new("Hello\nWorld\nFoo\nBar!", 7)}
	
	it "should know about line numbers" do
		expect(subject.to_i).to be == 7
		expect(subject.to_s).to be == "[2]"
		expect(subject.line_text).to be == "World"
		
		expect(subject.line_number).to be == 2
		expect(subject.line_range.min).to be == 6
		expect(subject.line_offset).to be == 1
	end
end
