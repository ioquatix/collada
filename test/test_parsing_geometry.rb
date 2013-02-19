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

class TestParsingGeometry < Test::Unit::TestCase
	Attribute = Collada::Parser::Attribute
	
	def test_accessors
		parameters = [
			Collada::Parser::Parameter.new(:x, :float),
			Collada::Parser::Parameter.new(nil, :float),
			Collada::Parser::Parameter.new(:z, :float),
		]
		
		accessor = Collada::Parser::Accessor.new(
			[1, 2, 3, 4, 5, 6],
			parameters, 2
		)
		
		assert_equal [[:x, 1], [:z, 3]], accessor[0]
		assert_equal [[:x, 4], [:z, 6]], accessor[1]
		
		assert_equal 2, accessor.size
		assert_equal [[[:x, 1], [:z, 3]], [[:x, 4], [:z, 6]]], accessor.to_a
	end
	
	def test_sources
		chunk = <<-EOF
		<?xml version="1.0" encoding="utf-8"?>
		<mesh>
			<source id="position">
				<float_array id="values" count="30">
					1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
				</float_array>
				<technique_common>
					<accessor source="#values" count="3" stride="10">
						<param name="px" type="float"/>
						<param name="py" type="float"/>
						<param name="pz" type="float"/>
					</accessor>
				</technique_common>
			</source>
			<source id="normal">
				<technique_common>
					<accessor source="#values" offset="3" count="3" stride="10">
						<param name="nx" type="float"/>
						<param name="ny" type="float"/>
						<param name="nz" type="float"/>
					</accessor>
				</technique_common>
			</source>
			<source id="mapping">
				<technique_common>
					<accessor source="#values" offset="6" count="3" stride="10">
						<param name="mu" type="float"/>
						<param name="mv" type="float"/>
					</accessor>
				</technique_common>
			</source>

			<triangles count="1">
				<input semantic="POSITION" source="#position" offset="0"/>
				<input semantic="NORMAL"   source="#normal" offset="0"/>
				<input semantic="TEXCOORD" source="#mapping" offset="0"/>
				<p>0 1 2</p> 
			</triangles>
		</mesh>
		EOF
		
		doc = REXML::Document.new(chunk)
		mesh = Collada::Parser::Geometry::Mesh.parse(doc, doc.elements['mesh'])
		
		expected = [
			[
				Attribute.position(:px => 1.0, :py => 2.0, :pz => 3.0),
				Attribute.normal(:nx => 4.0, :ny => 5.0, :nz => 6.0),
				Attribute.texcoord(:mu => 7.0, :mv => 8.0)
			],
			[
				Attribute.position(:px => 11.0, :py => 12.0, :pz => 13.0),
				Attribute.normal(:nx => 14.0, :ny => 15.0, :nz => 16.0),
				Attribute.texcoord(:mu => 17.0, :mv => 18.0)
			],
			[
				Attribute.position(:px => 21.0, :py => 22.0, :pz => 23.0),
				Attribute.normal(:nx => 24.0, :ny => 25.0, :nz => 26.0),
				Attribute.texcoord(:mu => 27.0, :mv => 28.0)
			],
		]
		
		assert_equal expected[0], mesh.polygons.vertex(0)
		assert_equal expected[1], mesh.polygons.vertex(1)
		assert_equal expected[2], mesh.polygons.vertex(2)
	end
	
	def test_sources_skipping
		chunk = <<-EOF
		<?xml version="1.0" encoding="utf-8"?>
		<mesh>
			<source id="test1">
				<float_array id="values" count="9">
				1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0
				</float_array>
				<technique_common>
					<accessor source="#values" count="3" stride="3">
						<param name='px' type="float"/>
						<param type="float"/>
						<param name='pz' type="float"/>
					</accessor>
				</technique_common>
			</source> 

			<triangles count="1">
				<input semantic="POSITION" source="#test1" offset="0"/>
				<p>0 1 2</p> 
			</triangles>
		</mesh>
		EOF
		
		doc = REXML::Document.new(chunk)
		mesh = Collada::Parser::Geometry::Mesh.parse(doc, doc.elements['mesh'])
		
		expected = [
			[Attribute.position(:px => 1.0, :pz => 3.0)],
			[Attribute.position(:px => 4.0, :pz => 6.0)],
			[Attribute.position(:px => 7.0, :pz => 9.0)],
		]
		
		assert_equal expected[0], mesh.polygons.vertex(0)
		assert_equal expected[1], mesh.polygons.vertex(1)
		assert_equal expected[2], mesh.polygons.vertex(2)
	end
	
	def test_library_geometry
		path = File.expand_path("../sample.dae", __FILE__)
		
		doc = REXML::Document.new(File.open(path))
		library = Collada::Parser::Library.parse(doc)
		
		mesh = library[:geometries].first.mesh
		
		expected = [
			[
				[Attribute.position({:X=>1.0, :Y=>1.0, :Z=>-1.0}), Attribute.vertex(index: 0), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>-1.0})],
				[Attribute.position({:X=>1.0, :Y=>-1.0, :Z=>-1.0}), Attribute.vertex(index: 1), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>-1.0})],
				[Attribute.position({:X=>-1.0, :Y=>-1.0, :Z=>-1.0}), Attribute.vertex(index: 2), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>-1.0})],
				[Attribute.position({:X=>-1.0, :Y=>1.0, :Z=>-1.0}), Attribute.vertex(index: 3), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>-1.0})]
			],
			[
				[Attribute.position({:X=>1.0, :Y=>1.0, :Z=>1.0}), Attribute.vertex(index: 4), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>1.0})],
				[Attribute.position({:X=>-1.0, :Y=>1.0, :Z=>1.0}), Attribute.vertex(index: 7), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>1.0})],
				[Attribute.position({:X=>-1.0, :Y=>-1.0, :Z=>1.0}), Attribute.vertex(index: 6), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>1.0})],
				[Attribute.position({:X=>1.0, :Y=>-1.0, :Z=>1.0}), Attribute.vertex(index: 5), Attribute.normal({:X=>0.0, :Y=>0.0, :Z=>1.0})]
			],
		]
		
		polygons = mesh.polygons.first(2)
		polygons.each_with_index do |polygon, index|
			assert_equal expected[index], polygon
		end
	end
end
