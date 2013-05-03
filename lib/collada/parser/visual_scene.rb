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
		class VisualScene
			class NodeReference < Reference
				def initialize(url)
					super :nodes, url
				end
				
				def lookup(scene)
					scene[id]
				end
			end
			
			class GeometryInstance < Reference
				def initialize(url)
					super :geometries, url
				end
				
				def self.parse(doc, element)
					self.new(element.attributes['url'])
				end
			end
			
			class ControllerInstance < Reference
				def initialize(url, skeleton)
					super :controllers, url
					
					# This references the node for the skeleton:
					@skeleton = skeleton
				end
				
				attr :skeleton
				
				def self.parse(doc, element)
					skeleton = NodeReference.new(element.elements['skeleton'].text)
					
					self.new(element.attributes['url'], skeleton)
				end
			end
			
			INSTANCE_ELEMENTS = [
				['instance_geometry', GeometryInstance],
				['instance_controller', ControllerInstance],
			]
			
			class Node
				def initialize(id, sid, name, type, transforms, instances, children, attributes = {})
					@id = id
					@sid = sid
					@name = name
					@type = type
					
					@transforms = transforms
					
					@instances = instances
					
					@children = children
					@children.each {|child| child.attach!(self)}
					
					@attributes = attributes
				end
				
				def attach!(parent)
					@parent = parent
				end
				
				attr :parent
				
				attr :id
				attr :sid
				
				attr :name
				attr :type
				
				attr :transforms
				
				attr :instances
				attr :children
				
				attr :attributes
				
				def inspect
					"\#<#{self.class} #{id} -> [#{children.keys.join(', ')}]>"
				end
				
				def local_transform_matrix
					Transforms.for(@transforms)
				end
				
				def transform_matrix
					if parent
						parent.transform_matrix * local_transform_matrix
					else
						local_transform_matrix
					end
				end
				
				def parents(type = nil)
					result = []
					
					parent = @parent
					
					while parent
						result << parent if !type || parent.type == type
						
						parent = parent.parent
					end
					
					return result
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
					
					INSTANCE_ELEMENTS.each do |(element_name, klass)|
						element.elements.each(element_name) do |instance_element|
							instances << klass.parse(doc, instance_element)
						end
					end
					
					return instances
				end
				
				def self.parse_children(doc, element)
					OrderedMap.parse(element, 'node') do |node_element|
						Node.parse(doc, node_element)
					end
				end
				
				def self.parse(doc, element)
					id = element.attributes['id']
					sid = element.attributes['sid']
					
					name = element.attributes['name']
					type = (element.attributes['type'] || 'node').downcase.to_sym
					
					transforms = parse_transforms(doc, element)
					instances = parse_instances(doc, element)
					children = parse_children(doc, element)
					
					self.new(id, sid, name, type, transforms, instances, children, element.attributes)
				end
			end
			
			def initialize(nodes)
				@nodes = nodes
				@named = {}
				
				traverse(@nodes) do |node|
					@named[node.id] = node
				end
			end
			
			attr :nodes
			attr :named
			
			def [] (id)
				@named[id]
			end
			
			def self.parse(doc, element)
				nodes = Node.parse_children(doc, element)
				
				self.new(nodes)
			end
			
			def traverse(nodes = @nodes, &block)
				nodes.each do |node|
					catch(:pass) do
						yield node
						
						traverse(node.children, &block)
					end
				end
			end
		end
	end
end
