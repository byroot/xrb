#!/usr/bin/env ruby
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

require 'trenni/parsers'
require 'trenni/entities'
require 'trenni/template'
require 'trenni/markup'

RSpec.shared_context "html parsers" do
	let(:delegate) {Trenni::ParseDelegate.new}
	let(:buffer) {Trenni::Buffer(subject)}
	let(:parsers) {Trenni::Parsers}
	let(:entities) {Trenni::Entities::HTML5}
	let(:events) {parsers.parse_markup(buffer, delegate, entities); delegate.events}
end

RSpec.shared_context "valid markup" do
	include_context "html parsers"
	
	it "should parse without error" do
		expect{events}.to_not raise_error
	end
end

RSpec.describe "<br/>" do
	include_context "valid markup"
	
	it "should parse self-closing tag" do
		expect(events).to be == [
			[:open_tag_begin, "br", 1],
			[:open_tag_end, true],
		]
	end
end

RSpec.describe "<!DOCTYPE html>" do
	include_context "valid markup"
	
	it "should parse doctype" do
		expect(events).to be == [
			[:doctype, "<!DOCTYPE html>"]
		]
	end
end

RSpec.describe "<?r foo=bar?>" do
	include_context "valid markup"
	
	it "should parse instruction" do
		expect(events).to be == [
			[:instruction, "<?r foo=bar?>"]
		]
	end
end

RSpec.describe %Q{<!--comment-->} do
	include_context "valid markup"
	
	it "should parse comment" do
		expect(events).to be == [
			[:comment, "<!--comment-->"]
		]
	end
end

RSpec.describe "<tag key=\"A&amp;B\" />" do
	include_context "valid markup"
	
	it "should parse escaped attributes" do
		expect(events).to be == [
			[:open_tag_begin, "tag", 1],
			[:attribute, "key", "A&B"],
			[:open_tag_end, true],
		]
	end
end

RSpec.describe "<foo bar=\"20\" baz>Hello World</foo>" do
	include_context "valid markup"
	
	it "should parse tag with content" do
		expect(events).to be == [
			[:open_tag_begin, "foo", 1],
			[:attribute, "bar", "20"],
			[:attribute, "baz", true],
			[:open_tag_end, false],
			[:text, "Hello World"],
			[:close_tag, "foo", 31],
		]
	end
	
	it "should have same encoding" do
		expect(events[0][1].encoding).to be == subject.encoding
		expect(events[1][1].encoding).to be == subject.encoding
		expect(events[2][1].encoding).to be == subject.encoding
		expect(events[4][1].encoding).to be == subject.encoding
		expect(events[5][1].encoding).to be == subject.encoding
	end
	
	it "should track entities" do
		expect(events[1][2]).to be_kind_of Trenni::Markup
		expect(events[4][1]).to be_kind_of Trenni::Markup
	end
end

RSpec.describe "<test><![CDATA[Hello World]]></test>" do
	include_context "valid markup"
	
	it "should parse CDATA" do
		expect(events).to be == [
			[:open_tag_begin, "test", 1],
			[:open_tag_end, false],
			[:cdata, "<![CDATA[Hello World]]>"],
			[:close_tag, "test", 31],
		]
	end
end

RSpec.describe "<foo bar=\"\" baz />" do
	include_context "valid markup"
	
	it "should parse empty attributes" do
		expect(events).to be == [
			[:open_tag_begin, "foo", 1],
			[:attribute, "bar", ""],
			[:attribute, "baz", true],
			[:open_tag_end, true],
		]
	end
end

RSpec.describe "<p attr=\"foo&amp;bar\">&quot;</p>" do
	include_context "valid markup"
	
	let(:template_text) {%q{<p attr="#{events[1][2]}">#{events[3][1]}</p>}}
	let(:template_buffer) {Trenni::Buffer(template_text)}
	let(:template) {Trenni::MarkupTemplate.new(template_buffer)}
	
	it "should parse empty attributes" do
		expect(events).to be == [
			[:open_tag_begin, "p", 1],
			[:attribute, "attr", "foo&bar"],
			[:open_tag_end, false],
			[:text, "\""],
			[:close_tag, "p", 30]
		]
	end
	
	it "generates same output as input" do
		result = template.to_string(self)
		expect(result).to be == subject
	end
	
	it "should track entities" do
		expect(events[1][2]).to_not be_kind_of Trenni::Markup
		expect(events[3][1]).to_not be_kind_of Trenni::Markup
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
		#dump_events!
		
		expected_events.each_with_index do |event, index|
			expect(events[index]).to be == event
		end
	end
end

RSpec.describe "corpus/large" do
	it_behaves_like "valid markup file", description
end

RSpec.shared_context "invalid markup" do
	include_context "html parsers"
	
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

RSpec.describe "<p>\nこんにちは World<p" do
	include_context "invalid markup"

	let(:error) {events rescue $!}
	
	it "should fail on line 2" do
		expect(error.location.line_number).to be == 2
	end
	
	it "should fail at offset 23" do
		expect(error.location.line_offset).to be == 23
	end
end

RSpec.describe Trenni::Location do
	subject{described_class.new("Hello\nWorld\nFoo\nBar!", 7)}
	
	it "should know about line numbers" do
		expect(subject.to_i).to be == 7
		expect(subject.to_s).to be == "[2:1]"
		expect(subject.line_text).to be == "World"
		
		expect(subject.line_number).to be == 2
		expect(subject.line_range.min).to be == 6
		expect(subject.line_offset).to be == 1
	end
end
