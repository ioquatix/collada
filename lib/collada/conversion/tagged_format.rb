
module Collada
	module Conversion
		class TaggedFormat
			class GeometryError < StandardError
			end

			TEXCOORD = lambda {|value| [value[:S], -value[:T] + 1.0]}

			VERTEX_FORMATS = {
				"p3n3" => VertexFormat[position: [:X, :Y, :Z], normal: [:X, :Y, :Z]],
				"p3n3m2" => VertexFormat[position: [:X, :Y, :Z], normal: [:X, :Y, :Z], texcoord: TEXCOORD],
				"p3n3m2b2" => VertexFormat[position: [:X, :Y, :Z], normal: [:X, :Y, :Z], texcoord: TEXCOORD, bones: WeightFormat[4]],
				"p3n3m2b4" => VertexFormat[position: [:X, :Y, :Z], normal: [:X, :Y, :Z], texcoord: TEXCOORD, bones: WeightFormat[4]],
			}

			def initialize(options, library, output = nil)
				@options = options
				@library = library
		
				@output_vertex_format = VERTEX_FORMATS[@options[:vertex_format]]
		
				@output = output || $stdout
		
				@top = {}
				@nodes = {}
			end
	
			def dump_geometry(scene, node, instance, skeleton = nil)
				vertex_format = @output_vertex_format.with_vertex_index
				geometry = instance.lookup(@library)
		
				mesh = Mesh.new
		
				weights = skeleton.indexed_weights if skeleton
		
				geometry.mesh.polygons.each do |polygon|
					if polygon.count != 3
						raise GeometryError.new("Non-triangular surfaces ")
					end
					
					polygon.each do |vertex_attributes|
						vertex = Collada::Conversion::Vertex.new(vertex_attributes, vertex_format)
				
						vertex.attributes[:bones] = weights[vertex.index] if weights
				
						mesh << vertex
					end
				end
		
				@output.puts "#{geometry.id}: mesh triangles"
		
				@output.puts "	indices: array index16"
				mesh.indices.each_slice(12) do |indices|
					@output.puts "		#{indices.flatten.collect{|i| i.to_s.rjust(5)}.join}"
				end
				@output.puts "	end"
		
				@output.puts "	vertices: array vertex-#{@options[:vertex_format]}"
				mesh.vertices.size.times do |index|
					vertex = mesh.indexed[index]
					@output.puts "		#{vertex.to_a(@output_vertex_format).collect{|v| v.to_s.rjust(12)}.join(' ')}"
				end
				@output.puts "	end"
		
				@output.puts "end"
		
				@top[geometry.name || geometry.id] = geometry.id
		
				return geometry
			end
	
			def dump_controller(scene, node, instance)
				controller = instance.lookup(@library)
				if controller.bind_pose_transform != Matrix.identity(4)
					raise ArgumentError.new("Non-identity bind pose transform is not supported by this exporter!")
				end
		
				top_joint = scene[instance.skeleton.id]
				skeleton = Collada::Conversion::Skeleton.new(@library, scene, top_joint, controller)
		
				geometry = dump_geometry(scene, node, controller.source, skeleton)
		
				indexed_weights = skeleton.indexed_weights
		
				@output.puts "#{controller.id}: skeleton"
		
				indexed_bones = {}
				@output.puts "	bones: array skeleton-bone"
				skeleton.bones.each.with_index do |(parent, bone), index|
					indexed_bones[bone.id] = index
					@output.puts "		#{bone.id} #{parent.to_s.rjust(5)}\t#{bone.transform_matrix.to_a.flatten.join(' ')}"
				end
				@output.puts "	end"
		
				# Extract out the animations that transform the bones:
				channels = {}
				start_time = 0.0
				end_time = 0.0
				@library[:animations].each do |animation|
					animation.channels.each do |channel|
						channels[channel.target] = channel
				
						# Extract out the end time if possible:
						attributes = Collada::Parser::Attribute.to_hash(channel.source[-1])
						end_time = attributes[:input][:TIME] || 0.0
					end
				end
		
				@output.puts "	sequences: offset-table"
				@output.puts "		default: skeleton-animation #{start_time} #{end_time}"
				@output.puts "			key-frames: array skeleton-animation-key-frame"
				skeleton.bones.each do |(parent, bone)|
					channel = channels["#{bone.id}/transform"]
			
					next unless channel
			
					channel.source.count.times do |index|
						attributes = Collada::Parser::Attribute.merge(channel.source[index])
						@output.puts "				" + [indexed_bones[bone.id], attributes[:INTERPOLATION].downcase, attributes[:TIME], attributes[:TRANSFORM].to_a].flatten.join(' ')
					end
				end
				@output.puts "			end"
				@output.puts "		end"
				@output.puts "	end"
		
				@output.puts "end"
		
				@top[controller.name || controller.id] = controller.id
		
				return geometry, skeleton
			end
	
			def dump_instances(instances, indent = "")
			end
	
			def dump_nodes(nodes, indent = "")
				nodes.each do |node|
					next unless node.type == :node
			
					@output.puts indent + "node #{node.id}"
					@output.puts indent + "	#{node.local_transform_matrix.to_a.flatten.join(' ')}"
			
					dump_instances(node.instances, indent + "\t")
					dump_nodes(node.children, indent + "\t")
			
					@output.puts indent + "end"
				end
			end
	
			def dump
				@nodes = {}
		
				@library[:visual_scenes].each do |scene|
					scene.traverse do |node|
						$stderr.puts node.inspect.color(:blue)
				
						node.instances.each do |instance|
							case instance
							when Collada::Parser::VisualScene::GeometryInstance
								geometry = dump_geometry(scene, node, instance)
							when Collada::Parser::VisualScene::ControllerInstance
								geometry, skeleton = dump_controller(scene, node, instance)
							end
						end
					end
			
					if @options[:nodes]
						dump_nodes(scene.nodes)
					end
				end
		
				@output.puts "top: offset-table"
				@top.each do |name, label|
					@output.puts "	#{name}: $#{label}"
				end
				@output.puts "end"
			end
		end
	end
end
