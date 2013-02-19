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

module Collada
	module Parser
		class Geometry
			class Mesh
				# A source that provides individual vertices:
				class Vertices
					include Enumerable
					
					def initialize(id, inputs)
						@id = id
						@inputs = inputs
					end
					
					attr :id
					attr :inputs
					
					def size
						@inputs.collect{|input| input.size}.max
					end
					
					# Vertices by index, same interface as Input.
					def [] index
						@inputs.collect do |input|
							input[index]
						end + [Attribute.new(:vertex, :index => index)]
					end
					
					def self.parse_inputs(doc, element, sources = {})
						OrderedMap.parse(element, 'input') do |input_element|
							Input.parse(doc, input_element, sources)
						end
					end
					
					def self.parse(doc, element, sources = {})
						inputs = parse_inputs(doc, element, sources)
						
						self.new(element.attributes['id'], inputs)
					end
				end
				
				# Vertices are organised as triangles
				class Triangles
					def vertex_count index
						3
					end
				end
				
				# Vertices are organised as arbitrary ngons.
				class PolyList
					def initialize(counts)
						@counts = counts
					end
					
					def vertex_count index
						@counts[index]
					end
					
					def self.parse(doc, element)
						counts = element.elements['vcount'].text.strip.split(/\s+/).collect &:to_i
						
						self.new(counts)
					end
				end
				
				class Polygons
					include Enumerable
					
					def initialize(inputs, indices, count, elements)
						@inputs = inputs
						@indices = indices
						
						# The total number of polygons:
						@count = count
						
						# The number of vertices per polygon:
						@elements = elements
						
						# The number of indices per vertex:
						@stride = @inputs.sort_by(&:offset).last.offset + 1
					end
					
					attr :inputs
					attr :indices
					
					# Element count:
					attr :count
					
					# Per-element data:
					attr :elements
					
					# Number of indices consumed per vertex:
					attr :stride
					
					def size
						@count
					end
					
					# Vertices by index:
					def vertex(index)
						offset = @stride * index
						
						attributes = @inputs.collect do |input|
							input[@indices[offset + input.offset]]
						end
						
						return Attribute.flatten(attributes)
					end
					
					def each_indices
						return to_enum(:each_indices) unless block_given?
						
						vertex_offset = 0
						
						@count.times do |index|
							# There are n vertices per face:
							vertex_count = @elements.vertex_count(index)
							
							# Grap all the vertices
							polygon = vertex_count.times.collect do |vertex_index|
								vertex_offset + vertex_index
							end
							
							yield polygon
							
							vertex_offset += vertex_count
						end
					end
					
					# Iterate over each polygon/triangle:
					def each
						each_indices do |indices|
							vertices = indices.collect {|index| vertex(index)}
							
							yield vertices
						end
					end
					
					def self.parse_inputs(doc, element, sources = {})
						OrderedMap.parse(element, 'input') do |input_element|
							Input.parse(doc, input_element, sources)
						end
					end
					
					def self.parse_indices(doc, element)
						element.elements['p'].text.strip.split(/\s+/).collect &:to_i
					end
					
					def self.parse(doc, element, sources = {})
						inputs = parse_inputs(doc, element, sources)
						indices = parse_indices(doc, element)
						count = element.attributes['count'].to_i
						
						if element.name == 'triangles'
							self.new(inputs, indices, count, Triangles.new)
						elsif element.name == 'polylist'
							self.new(inputs, indices, count, PolyList.parse(doc, element))
						else
							raise UnsupportedFeature.new(element)
						end
					end
				end
				
				def initialize(sources, vertices, polygons)
					@sources = sources
					@vertices = vertices
					@polygons = polygons
				end
				
				attr :sources
				attr :vertices
				attr :polygons
				
				def self.parse(doc, element)
					arrays = Source.parse_arrays(doc, element)
					
					sources = OrderedMap.parse(element, 'source') do |source_element|
						Source.parse(doc, source_element, arrays)
					end
					
					if (vertices_element = element.elements['vertices'])
						vertices = Vertices.parse(doc, vertices_element, sources)
						sources.append(vertices.id, vertices)
					end
					
					if (polygons_element = element.elements['triangles | polylist'])
						polygons = Polygons.parse(doc, polygons_element, sources)
					end
					
					self.new(sources, vertices, polygons)
				end
			end
			
			def initialize(id, mesh, attributes)
				@id = id
				
				@mesh = mesh
				
				@attributes = attributes
			end
			
			attr :id
			attr :mesh
			attr :attributes
			
			def self.parse(doc, element)
				id = element.attributes['id']
				
				mesh = Mesh.parse(doc, element.elements['mesh'])
				
				self.new(id, mesh, element.attributes)
			end
		end
	end
end
