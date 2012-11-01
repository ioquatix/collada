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
				class Parameter
					def initialize(name, type)
						@name = name
						@type = type
					end
					
					attr :name
					attr :type
					
					def self.parse(doc, element)
						self.new(element.attributes['name'], element.attributes['type'].to_sym)
					end
				end
				
				class Accessor
					include Enumerable
					
					def initialize(array, parameters, options = {})
						@array = array
						@parameters = parameters
						@names = parameters.collect{|parameter| parameter.name}
						
						@offset = (options[:offset] || 0).to_i
						@stride = (options[:stride] || parameters.size).to_i
					end
					
					attr :array
					attr :parameters
					attr :names
					
					attr :offset
					attr :stride
					
					def read index
						base = @offset + (index * @stride)
						values = @array[base, @parameters.size]
						
						@names.zip(values)
					end
					
					def [] index
						read(index).delete_if{|(name, value)| name == nil}
					end
					
					def size
						(@array.size - @offset) / @stride
					end
					
					def each
						size.times.each do |i|
							yield self[i]
						end
					end
					
					def self.parse_parameters(doc, element)
						OrderedMap.parse(element, 'param', 'name') do |param_element|
							Parameter.parse(doc, param_element)
						end
					end
					
					def self.parse(doc, element, arrays = {})
						if (array_id = element.attributes['source'])
							array_id.sub!(/^#/, '')
							
							array = arrays[array_id]
						else
							array = Mesh.parse_arrays(doc, element).first
						end
						
						parameters = parse_parameters(doc, element)
						
						options = {
							:offset => element.attributes['offset'],
							:stride => element.attributes['stride'],
						}
						
						self.new(array, parameters, options)
					end
				end
				
				class Source
					def initialize(id, accessor)
						@id = id
						@accessor = accessor
					end
					
					attr :id
					attr :accessor
					
					def self.parse(doc, element, arrays = {})
						accessor = Accessor.parse(doc, element.elements['technique_common/accessor'], arrays)
						
						self.new(element.attributes['id'], accessor)
					end
				end
				
				class Input
					def initialize(semantic, source, offset = 0)
						@semantic = semantic
						@source = source
						@offset = offset
					end
					
					attr :semantic
					attr :source
					attr :offset
					
					def inspect
						"<Input: #{@semantic}>"
					end
					
					def self.parse(doc, element, sources = {})
						semantic = element.attributes['semantic']

						if (source_id = element.attributes['source'])
							source_id.sub!(/^#/, '')
							source = sources[source_id]
						end

						offset = element.attributes['offset'] || 0

						self.new(semantic, source, offset.to_i)
					end
				end
				
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
				
				def self.parse_arrays(doc, element)
					OrderedMap.parse(element, '//float_array | //int_array', 'name') do |array_element|
						array_element.text.strip.split(/\s+/).collect &:to_f
					end
				end
				
				def self.parse(doc, element)
					arrays = parse_arrays(doc, element)
					
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
