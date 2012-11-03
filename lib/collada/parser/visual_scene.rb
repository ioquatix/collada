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
			class Node
				def initialize(id, transforms, instance, children, attributes = {})
					@id = id
					@transforms = []
					
					@instance = instance
					@children = children
					
					@attributes = attributes
				end
				
				attr :id
				attr :transforms
				
				attr :instance
				attr :children
				
				attr :attributes
				
				def self.parse_transforms(doc, element)
					transforms = []
					
					element.elements.each('translate | rotate | scale') do |transform_element|
						values = transform_element.text.strip.split(/\s+/).collect &:to_f
						transforms << [transform_element.name, values]
					end
					
					return transforms
				end
				
				def self.parse_instance(doc, element)
					if (instance_geometry_element = element.elements['instance_geometry'])
						url = instance_geometry_element.attributes['url']
						
						Reference.new(:geometry, url.sub(/^#/, ''))
					end
				end
				
				def self.parse_children(doc, element)
					children = []
					
					element.elements.each('node') do |node_element|
						children << parse(doc, node_element)
					end
					
					return children
				end
				
				def self.parse(doc, element)
					id = element.attributes['id']
					
					transforms = parse_transforms(doc, element)
					instance = parse_instance(doc, element)
					children = parse_children(doc, element)
					
					self.new(id, transforms, instance, children, element.attributes)
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

	end
end
