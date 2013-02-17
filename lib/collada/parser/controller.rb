# Copyright, 2013, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

module Collada
	module Parser
		class Controller
			class Skin < Controller
				class Joints < Sampler
				end
				
				class VertexWeights < Sampler
					include Enumerable
					
					def initialize(id, inputs, counts, vertices)
						super id, inputs
						
						@counts = counts
						@vertices = vertices
						
						# The number of indices per vertex:
						@stride = @inputs.sort_by(&:offset).last.offset + 1
					end
					
					attr :counts
					attr :vertices
					
					def size
						@counts.size
					end
					
					# Vertices by index:
					def vertex(index)
						offset = @stride * index
						
						attributes = @inputs.collect do |input|
							input[@vertices[offset + input.offset]]
						end
						
						return Attribute.flatten(attributes)
					end
					
					def each
						vertex_offset = 0
						
						@counts.each do |count|
							# Grap all the vertices
							weights = count.times.collect do |vertex_index|
								vertex(vertex_offset + vertex_index)
							end
							
							yield weights
							
							vertex_offset += count
						end
					end
					
					def self.parse(doc, element, sources)
						inputs = parse_inputs(doc, element, sources)
						
						counts = element.elements['vcount'].text.split(/\s+/).collect &:to_i
						vertices = element.elements['v'].text.split(/\s+/).collect &:to_i
						
						self.new(element.attributes['id'], inputs, counts, vertices)
					end
				end
				
				def initialize(id, name, bind_shape_transform, sources, joints, weights)
					super id, name
					
					@bind_shape_transform = bind_shape_transform
					
					@sources = sources
					@joints = joints
					
					@weights = weights
				end
				
				attr :bind_shape_transform
				
				attr :sources
				attr :joints
				
				attr :weights
				
				def self.parse(doc, controller_element, element)
					id = controller_element.attributes['id']
					name = controller_element.attributes['name']
					
					bind_shape_transform = extract_float4x4_matrix(element.elements['bind_shape_matrix'].text)
					
					arrays = Source.parse_arrays(doc, element)
				
					sources = OrderedMap.parse(element, 'source') do |source_element|
						Source.parse(doc, source_element, arrays)
					end
					
					joints = Joints.parse(doc, element.elements['joints'], sources)
					
					vertex_weights = VertexWeights.parse(doc, element.elements['vertex_weights'], sources)
					
					self.new(id, name, bind_shape_transform, sources, joints, vertex_weights)
				end
				
				private
				
				def self.extract_float4x4_matrix(text)
					values = text.split(/\s+/).collect &:to_f
					
					Matrix[*(values.each_slice(4).to_a)]
				end
			end
			
			def initialize(id, name)
				@id = id
				@name = name
			end
			
			attr :id
			attr :name
			
			def self.parse(doc, element)
				element.elements.each('skin') do |skin_element|
					return Skin.parse(doc, element, skin_element)
				end
			end
		end
	end
end
