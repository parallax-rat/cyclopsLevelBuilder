# MIT License
#
# Copyright (c) 2023 Mark McKay
# https://github.com/blackears/cyclopsLevelBuilder
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends Resource
class_name ControlMesh


class VertexInfo:
	var index:int
	var point:Vector3
	var edge_indices:Array[int] = []
	
	func _init(_index:int, _point:Vector3 = Vector3.ZERO):
		index = _index
		point = _point
		
	func _to_string():
		var s:String = "%s %s [" % [index, point]
		for i in edge_indices:
			s += "%s " %  i
		s += "]"
			
		return s

class EdgeInfo:
	var index:int
	var start_index:int
	var end_index:int
	var face_indices:Array[int] = []
	
	func _init(_index:int, _start:int = 0, _end:int = 0):
		index = _index
		start_index = _start
		end_index = _end

	func _to_string():
		var s:String = "%s %s %s [" % [index, start_index, end_index]
		for i in face_indices:
			s += "%s " % i
		s += "]"
		return s

class FaceInfo:
	var index:int
	var normal:Vector3
#	var vertex_indices:Array[int]
	var face_corner_indices:Array[int]
	var material_index:int
	
	func _init(_index:int, _face_corner_indices:Array[int] = [], _mat_index:int = 0):
		index = _index
		face_corner_indices = _face_corner_indices
		material_index = _mat_index

	func _to_string():
		var s:String = "%s %s %s [" % [index, normal, material_index]
		for i in face_corner_indices:
			s += "%s " % i
		s += "]"
		return s

class FaceCornerInfo:
	var index:int
	var uv:Vector2
	var vertex_index:int
	var face_index:int
	
	func _init(_index:int, _vertex_index:int, _face_index:int):
		vertex_index = _vertex_index
		face_index = _face_index

	func _to_string():
		var s:String = "%s %s %s %s" % [index, uv, vertex_index, face_index]
		return s
		
	

var vertices:Array[VertexInfo] = []
var edges:Array[EdgeInfo] = []
var faces:Array[FaceInfo] = []
var face_corners:Array[FaceCornerInfo] = []

#var points:PackedVector3Array

func _init():
	init_block(Vector3.ZERO, Vector3.LEFT + Vector3.FORWARD, Vector3.UP)
#	dump()
	pass

func clear_lists():
	vertices = []
	edges = []
	faces = []
	face_corners = []

func init_block(p0:Vector3, p1:Vector3, p2:Vector3):
	
	var bounds:AABB = AABB(p0, Vector3.ZERO)
	bounds = bounds.expand(p1)
	bounds = bounds.expand(p2)
	
	var p000:Vector3 = bounds.position
	var p111:Vector3 = bounds.end
	var p001:Vector3 = Vector3(p000.x, p000.y, p111.z)
	var p010:Vector3 = Vector3(p000.x, p111.y, p000.z)
	var p011:Vector3 = Vector3(p000.x, p111.y, p111.z)
	var p100:Vector3 = Vector3(p111.x, p000.y, p000.z)
	var p101:Vector3 = Vector3(p111.x, p000.y, p111.z)
	var p110:Vector3 = Vector3(p111.x, p111.y, p000.z)
	
	init_prisim([p000, p001, p011, p010], p100 - p000)
	

func init_prisim(base_points:Array[Vector3], extrude_dir:Vector3):
	
	var verts:PackedVector3Array
	for p in base_points:
		verts.append(p)
	for p in base_points:
		verts.append(p + extrude_dir)

	var index_list:PackedInt32Array
	var face_len_list:PackedInt32Array
	
	var num_points:int = base_points.size()
	for i0 in num_points:
		var i1:int = wrap(i0 + 1, 0, num_points)
		
		index_list.append(i0)
		index_list.append(i1)
		index_list.append(i1 + num_points)
		index_list.append(i0 + num_points)
		face_len_list.append(4)
	
	for i0 in num_points:
#		index_list.append(i0)
		index_list.append(num_points - i0 - 1)
	face_len_list.append(num_points)
	
	for i0 in num_points:
		index_list.append(i0 + num_points)
#		index_list.append(num_points * 2 - i0 - 1)
	face_len_list.append(num_points)
	
	init_from_face_lists(verts, index_list, face_len_list)
	
	
func init_from_face_lists(verts:PackedVector3Array, index_list:PackedInt32Array, face_len_list:PackedInt32Array):
	clear_lists()

	for i in verts.size():
		var v:VertexInfo = VertexInfo.new(i, verts[i])	
		vertices.append(v)
	
	var vertex_index_offset:int = 0
	for face_index in face_len_list.size():
		var num_face_verts = face_len_list[face_index]
		if num_face_verts < 3:
			continue
		
		var face_corners_local:Array[int] = []
		for i in num_face_verts:
			var face_corner_index:int = face_corners.size()
			var face_corner:FaceCornerInfo = FaceCornerInfo.new(face_corner_index, index_list[vertex_index_offset], face_index)
			face_corners.append(face_corner)
			face_corners_local.append(face_corner_index)
			vertex_index_offset += 1
		
		var face:FaceInfo = FaceInfo.new(face_index, face_corners_local)
		faces.append(face)

		#Calc normal		
		var fc0:FaceCornerInfo = face_corners[face_corners_local[0]]
#		var vidx0 = fc0.vertex_index
		var p0:Vector3 = vertices[fc0.vertex_index].point
#
		var weighted_normal:Vector3
		for i in range(1, num_face_verts - 1):
			var fc1:FaceCornerInfo = face_corners[face_corners_local[i]]
			var fc2:FaceCornerInfo = face_corners[face_corners_local[i + 1]]
#			var vidx1 = fc1.vertex_index
#			var vidx2 = fc2.vertex_index
			var p1:Vector3 = vertices[fc1.vertex_index].point
			var p2:Vector3 = vertices[fc2.vertex_index].point

			var v1:Vector3 = p1 - p0
			var v2:Vector3 = p2 - p0
			weighted_normal += v2.cross(v1)
			
		face.normal = weighted_normal.normalized()
			
	#Calculate edges
	for face in faces:
		var num_corners = face.face_corner_indices.size()
		for i0 in num_corners:
			var i1:int = wrap(i0 + 1, 0, num_corners)
			var fc0:FaceCornerInfo = face_corners[face.face_corner_indices[i0]]
			var fc1:FaceCornerInfo = face_corners[face.face_corner_indices[i1]]
			
			var edge:EdgeInfo = get_edge(fc0.vertex_index, fc1.vertex_index)
			if !edge:
				var edge_idx = edges.size()
				edge = EdgeInfo.new(edge_idx, fc0.vertex_index, fc1.vertex_index)
				edges.append(edge)
			
				var v0:VertexInfo = vertices[fc0.vertex_index]
				v0.edge_indices.append(edge_idx)
				
				var v1:VertexInfo = vertices[fc1.vertex_index]
				v1.edge_indices.append(edge_idx)

			edge.face_indices.append(face.index)


func get_edge(vert_idx0:int, vert_idx1:int)->EdgeInfo:
	for e in edges:
		if e.start_index == vert_idx0 && e.end_index == vert_idx1:
			return e
		if e.start_index == vert_idx1 && e.end_index == vert_idx0:
			return e
	return null


#func build_mesh(material:Material)->ImmediateMesh:
func append_mesh(mesh:ImmediateMesh, material:Material):
	
#	var mesh:ImmediateMesh = ImmediateMesh.new()
	
	for face in faces:
		mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
#		print("face %s" % face.index)
		
		mesh.surface_set_normal(face.normal)
		
		var num_corners:int = face.face_corner_indices.size()
		for i in num_corners:
#			var idx = ((i + 1) >> 1) if i & 1 else wrap(num_corners - (i >> 1), 0, num_corners)
#			var idx = num_corners - (i + 1) / 2 if i & 1 else i / 2
			var idx = (i + 1) / 2 if i & 1 else wrap(num_corners - (i / 2), 0, num_corners)
			var fc:FaceCornerInfo = face_corners[face.face_corner_indices[idx]]
#			if i == 0:
#				idx = 0
			mesh.surface_add_vertex(vertices[fc.vertex_index].point)
#			print ("%s %s %s" % [idx, fc.vertex_index, control_mesh.vertices[fc.vertex_index].point])
	
		mesh.surface_end()
		
#	return mesh
	
func dump():
	print ("Verts")
	for v in vertices:
		print(v.to_string())	
	print ("Edges")
	for e in edges:
		print(e.to_string())	
	print ("Faces")
	for f in faces:
		print(f.to_string())	
	print ("Face Corners")
	for f in face_corners:
		print(f.to_string())	
