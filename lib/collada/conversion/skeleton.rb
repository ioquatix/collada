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

require 'collada/parser/support'
require 'collada/transforms'

module Collada
	module Conversion
		class Skeleton
			def initialize(library, scene, node, controller)
				@library = library
				@scene = scene
				@node = node
				
				@controller = controller
				
				extract_skeleton(node)
			end
			
			attr :library
			attr :scene
			attr :node
			attr :controller
			
			attr :top
			attr :bones
			attr :indexed
			
			def indexed_weights
				result = []
				
				@controller.weights.each do |vertex|
					output = []
					
					vertex.each do |weight|
						weight = Parser::Attribute.merge(weight)
						
						output << [@indexed[weight[:JOINT]], weight[:WEIGHT]]
					end
					
					# Sort bone weights in descending order:
					result << output.sort{|a,b| b[1] <=> a[1]}
				end
				
				return result
			end
			
			private
			
			def extract_skeleton(top)
				@bones = [[0, top]]
				@indexed = {top.id => 0}
				
				@scene.traverse(top.children) do |node|
					next unless node.type == :joint
					
					bone_index = indexed[node.parents(:joint).first.id]
					
					@indexed[node.id] = bones.size
					@bones << [bone_index, node]
				end
				
				return bones
			end
		end
	end
end
