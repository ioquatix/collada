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
require 'collada/conversion/skeleton'

class TestParsingGeometry < Test::Unit::TestCase
	def setup
		@path = File.expand_path("../animation.dae", __FILE__)
		@doc = REXML::Document.new(File.open(@path))
		@library = Collada::Parser::Library.parse(@doc)
	end
	
	Attribute = Collada::Parser::Attribute
	
	# We are going to load the animation file and check that it has some bones.
	def test_library_animation
		library = @library
		
		assert_equal 11, library[:animations].size
		
		# Extract out the animations that transform the bones:
		channels = {}
		library[:animations].each do |animation|
			animation.channels.each do |channel|
				channels[channel.target] = channel
			end
		end
		
		# Do they exist?
		assert channels['BoneA/transform']
		assert channels['BoneB/transform']
		
		# Are there three matricies?
		assert_equal 3, channels['BoneB/transform'].source.count
		
		# Extract the bones from the visual scene:
		bone_a = library[:visual_scenes].first.nodes['Armature'].children.first
		bone_b = bone_a.children.first
		
		# This tells us the position of the bone in the scene:
		assert_equal "BoneA", bone_a.id
		assert_equal :joint, bone_a.type
		puts bone_a.transform_matrix
		
		# ... but it doesn't tell us anything about how its connected to any related object:
		assert_equal "BoneB", bone_b.id
		assert_equal :joint, bone_b.type
		puts bone_b.transform_matrix
		
		# for that, we need to inspect a controller.
		controller = library[:visual_scenes].first.nodes['Cylinder'].instances.first.lookup(library)
		assert controller
		
		assert_equal Collada::Parser::Controller::Skin, controller.class
		
		weights = [
			[Attribute.joint({:JOINT=>"BoneA"}), Attribute.weight({:WEIGHT=>0.9576348})],
			[Attribute.joint({:JOINT=>"BoneB"}), Attribute.weight({:WEIGHT=>0.04236513})]
		]
		
		assert_equal weights, controller.weights.to_a[159]
	end
	
	def test_skeleton
		controller = @library[:controllers].first
		geometry = controller.source.lookup(@library)
		scene = @library[:visual_scenes].first
		
		skeleton = Collada::Conversion::Skeleton.new(@library, scene, scene['BoneA'], controller)
		
		assert_equal geometry.mesh.vertices.size, skeleton.indexed_weights.size
	end
end
