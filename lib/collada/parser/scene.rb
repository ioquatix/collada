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

require 'rexml/document'
require 'yaml'

module Collada
	module Parser
		class UnsupportedFeature < StandardError
		end
		
		class OrderedMap
			include Enumerable
			
			def initialize(ordered, indexed)
				@ordered = ordered
				@indexed = indexed
			end
			
			attr :ordered
			attr :indexed
			
			def [] key
				@indexed[key]
			end
			
			def each(&block)
				@ordered.each(&block)
			end
			
			def size
				@ordered.size
			end
			
			def self.parse(top, path, id_key = 'id')
				ordered = []
				indexed = {}
			
				top.elements.each(path) do |element|
					id = element.attributes[id_key]
					value = (yield element)

					indexed[id] = value if id
					ordered << value
				end
				
				return OrderedMap.new(ordered, indexed)
			end
		end
		
		class Geometry
			class Mesh
				class TriangleVertices
					def count(index)
						3
					end
				end
				
				class PolygonVertices
					def initialize(counts)
						@counts = counts
					end
					
					def count(index)
						@counts[index]
					end
					
					def self.parse(doc, element)
						counts = element.elements('vcount').text.strip.split(/\s+/).collect &:to_i
						
						self.new(counts)
					end
				end
				
				class Polygons
					include Enumerable
					
					def initialize(inputs, indices, count, vertices)
						@inputs = inputs
						@indices = indices
						
						# The total number of polygons:
						@count = count
						
						# The number of vertices per polygon:
						@vertices = vertices
						
						# The number of indices per vertex:
						@stride = @inputs.sort_by(&:offset).last.offset + 1
					end
					
					attr :inputs
					attr :indices
					
					# Element count:
					attr :count
					
					# Number of vertices per element:
					attr :vertices
					
					# Number of indices consumed per vertex:
					attr :stride
					
					def size
						@count
					end
					
					# Vertices by index:
					def [] index
						offset = @stride * index
						
						@inputs.collect do |input|
							input.source.accessor[@indices[offset + input.offset]]
						end
					end
					
					def each
						consumed = 0
						
						@count.times do |index|
							elements = @vertices.count(index)
							polygon = elements.times.collect{|edge| self[consumed + edge]}
							
							yield polygon
							
							consumed += elements
						end
					end
					
					def self.parse_inputs(doc, element, sources = {})
						OrderedMap.parse(element, '//input') do |input_element|
							Input.parse(doc, input_element, sources)
						end
					end
					
					def self.parse_indices(doc, element)
						element.elements['p'].text.strip.split(/\s+/).collect{|index| index.to_i - 1}
					end
					
					def self.parse(doc, element, sources = {})
						inputs = parse_inputs(doc, element, sources)
						indices = parse_indices(doc, element)
						count = element.attributes['count'].to_i
						
						if element.name == 'triangles'
							self.new(inputs, indices, count, TriangleVertices.new)
						elsif element.name == 'polylist'
							self.new(inputs, indices, count, PolygonVertices.parse(doc, element))
						else
							raise UnsupportedFeature.new(element)
						end
					end
				end
				
				def initialize(sources, polygons)
					@sources = sources
					@polygons = polygons
				end
				
				attr :sources
				attr :polygons
				
				def self.parse(doc, element)
					arrays = Source.parse_arrays(doc, element)
					
					sources = OrderedMap.parse(element, 'source') do |source_element|
						Source.parse(doc, source_element, arrays)
					end
					
					if (polygons_element = element.elements['triangles | polylist'])
						polygons = Polygons.parse(doc, polygons_element, sources)
					end
					
					self.new(sources, polygons)
				end
			end
			
			def initialize(mesh)
				@mesh = mesh
			end
			
			attr :mesh
			
			def self.parse(doc, element)
				mesh = Mesh.parse(doc, element.elements['mesh'])
				
				self.new(mesh)
			end
		end
		
		class VisualScene
			class Node
				def initialize(structure = {})
					@structure = structure
				end
				
				attr :structure
				
				def self.parse(doc, element)
					self.new(element)
				end
			end
			
			def initialize(nodes = [])
				@nodes = nodes
			end
			
			attr :nodes
			
			def self.parse(doc, element)
				nodes = []
				
				element.elements.each('node') do |element|
					nodes << Node.parse(doc, element)
				end
				
				self.new(nodes)
			end
		end
		
		class Library
			SECTIONS = {
				:visual_scenes => ['COLLADA/library_visual_scenes/visual_scene', VisualScene],
				:geometries => ['COLLADA/library_geometries/geometry', Geometry]
			}
			
			def initialize(sections = {})
				@sections = sections
			end
			
			def [] key
				@sections[key]
			end
			
			def self.parse(doc)
				sections = {}
				
				SECTIONS.each do |key, (path, klass)|
					sections[key] = OrderedMap.parse(doc, path) do |element|
						klass.parse(doc, element)
					end
				end
				
				return Library.new(sections)
			end
		end
		
		class Scene
			def initialize(library)
				@library = library
			end
			
			attr :library
			
			def self.parse(doc)
				scene = doc.elements['COLLADA/scene']
				
				library = Library.parse(doc)
			end
		end
	end
end
