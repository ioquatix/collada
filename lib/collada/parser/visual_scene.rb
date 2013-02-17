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
	module Parser
		class Reference
			def initialize(kind, id)
				@kind = kind
				
				@id = id
			end
			
			attr :kind
			attr :id
			
			def lookup(library)
				library[@kind].each do |item|
					return item if item.id == @id
				end
				
				return nil
			end
		end
		
		class VisualScene
			INSTANCE_ELEMENTS = [
				['instance_geometry', :geometries],
				['instance_controller', :controllers],
			]
			
			class Node
				def initialize(id, type, transforms, instances, children, attributes = {})
					@id = id
					@type = type
					
					@transforms = transforms
					
					@instances = instances
					@children = children
					
					@attributes = attributes
				end
				
				attr :id
				attr :type
				
				attr :transforms
				
				attr :instances
				attr :children
				
				attr :attributes
				
				def transform_matrix
					Transforms.for(@transforms)
				end
				
				def self.parse_transforms(doc, element)
					transforms = []
					
					element.elements.each('translate | rotate | scale | matrix') do |transform_element|
						values = transform_element.text.strip.split(/\s+/).collect &:to_f
						transforms << [transform_element.name.to_sym, values]
					end
					
					return transforms
				end
				
				def self.parse_instances(doc, element)
					instances = []
					
					INSTANCE_ELEMENTS.each do |(element_name, reference_type)|
						element.elements.each(element_name) do |instance_element|
							url = instance_element.attributes['url']
						
							instances << Reference.new(reference_type, url.gsub(/^#/, ''))
						end
					end
					
					return instances
				end
				
				def self.parse_children(doc, element)
					OrderedMap.parse(element, 'node', 'id') do |node_element|
						Node.parse(doc, node_element)
					end
				end
				
				def self.parse(doc, element)
					id = element.attributes['id']
					type = element.attributes['type']
					
					transforms = parse_transforms(doc, element)
					instances = parse_instances(doc, element)
					children = parse_children(doc, element)
					
					self.new(id, type, transforms, instances, children, element.attributes)
				end
			end
			
			def initialize(nodes)
				@nodes = nodes
			end
			
			attr :nodes
			
			def self.parse(doc, element)
				nodes = Node.parse_children(doc, element)
				
				self.new(nodes)
			end
		end

	end
end
