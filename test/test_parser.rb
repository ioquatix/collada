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

require 'pathname'
require 'test/unit'
require 'stringio'

require 'collada/parser'

class TestParser < Test::Unit::TestCase
	def test_accessors
		parameters = [
			Collada::Parser::Geometry::Mesh::Parameter.new('X', :float),
			Collada::Parser::Geometry::Mesh::Parameter.new(nil, :float),
			Collada::Parser::Geometry::Mesh::Parameter.new('Z', :float),
		]
		
		accessor = Collada::Parser::Geometry::Mesh::Accessor.new(
			[1, 2, 3, 4, 5, 6],
			parameters
		)
		
		assert_equal [['X', 1], ['Z', 3]], accessor[0]
		assert_equal [['X', 4], ['Z', 6]], accessor[1]
		
		assert_equal 2, accessor.size
		assert_equal [[["X", 1], ["Z", 3]], [["X", 4], ["Z", 6]]], accessor.to_a
	end
	
	def test_sources
		chunk = <<-EOF
		<?xml version="1.0" encoding="utf-8"?>
		<mesh>
			<source id="position">
				<float_array name="values" count="30">
					1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
				</float_array>
				<technique_common>
					<accessor source="#values" count="3" stride="10">
						<param name="PX" type="float"/>
						<param name="PY" type="float"/>
						<param name="PZ" type="float"/>
					</accessor>
				</technique_common>
			</source>
			<source id="normal">
				<technique_common>
					<accessor source="#values" offset="3" count="3" stride="10">
						<param name="NX" type="float"/>
						<param name="NY" type="float"/>
						<param name="NZ" type="float"/>
					</accessor>
				</technique_common>
			</source>
			<source id="mapping">
				<technique_common>
					<accessor source="#values" offset="6" count="3" stride="10">
						<param name="TU" type="float"/>
						<param name="TV" type="float"/>
					</accessor>
				</technique_common>
			</source>

			<triangles count="1">
				<input semantic="POSITION" source="#position" offset="0"/>
				<input semantic="NORMAL"   source="#normal" offset="0"/>
				<input semantic="TEXCOORD" source="#mapping" offset="0"/>
				<p>1 2 3</p> 
			</triangles>
		</mesh>
		EOF
		
		doc = REXML::Document.new(chunk)
		mesh = Collada::Parser::Geometry::Mesh.parse(doc, doc.elements['mesh'])
		
		expected = [
			[[["PX", 1.0], ["PY", 2.0], ["PZ", 3.0]], [["NX", 4.0], ["NY", 5.0], ["NZ", 6.0]], [["TU", 7.0], ["TV", 8.0]]],
			[[["PX", 11.0], ["PY", 12.0], ["PZ", 13.0]], [["NX", 14.0], ["NY", 15.0], ["NZ", 16.0]], [["TU", 17.0], ["TV", 18.0]]],
			[[["PX", 21.0], ["PY", 22.0], ["PZ", 23.0]], [["NX", 24.0], ["NY", 25.0], ["NZ", 26.0]], [["TU", 27.0], ["TV", 28.0]]],
		]
		
		assert_equal expected[0], mesh.polygons[0]
		assert_equal expected[1], mesh.polygons[1]
		assert_equal expected[2], mesh.polygons[2]
	end
end
