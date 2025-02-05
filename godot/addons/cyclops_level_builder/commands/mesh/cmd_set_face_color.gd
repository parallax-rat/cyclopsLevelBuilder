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
class_name CommandSetFaceColor
extends CyclopsCommand


class BlockFaceChanges extends RefCounted:
	var block_path:NodePath
	var face_indices:Array[int]
	var tracked_block_data:MeshVectorData

var color:Color = Color.WHITE

#Private
var block_map:Dictionary = {}

func add_face(block_path:NodePath, index:int):
	add_faces(block_path, [index])
	
func add_faces(block_path:NodePath, indices:Array[int]):
#	print("adding_face %s %s" % [block_path, indices])
	var changes:BlockFaceChanges
	if block_map.has(block_path):
		changes = block_map[block_path]
	else:
		changes = BlockFaceChanges.new()
		changes.block_path = block_path
		var block:CyclopsBlock = builder.get_node(block_path)
		changes.tracked_block_data = block.mesh_vector_data
		block_map[block_path] = changes

	for index in indices:
		if !changes.face_indices.has(index):
			changes.face_indices.append(index)
	

func _init():
	command_name = "Set Face Color"

func will_change_anything()->bool:
	#print("CommandSetFaceColor will_change_anything")
	print(block_map.keys())
	for block_path in block_map.keys():

		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
			
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)

		#print("checking block ", block_path)
		for f_idx in vol.faces.size():
			if rec.face_indices.has(f_idx):
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				if f.color != color:
					return true
				#print("face_vertex_indices ", f.face_vertex_indices)
				for fv in vol.face_vertices:
					if fv.face_index == f_idx:
						if fv.color != color:
							return true

	return false
	
	
func do_it():
	#print("set face color do_it")
#	print("sel uv_transform do_it()")
	for block_path in block_map.keys():
#		print("path %s" % block_path)
		
		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
			
		#print("block_path %s" % block_path)
		var vol:ConvexVolume = ConvexVolume.new()
		vol.init_from_mesh_vector_data(rec.tracked_block_data)

		for f_idx in vol.faces.size():
			if rec.face_indices.has(f_idx):
				#print("face_idx %s" % f_idx)
				var f:ConvexVolume.FaceInfo = vol.faces[f_idx]
				f.color = color
				#print("face_vertex_indices ", f.face_vertex_indices)
				#for fv_idx in f.face_vertex_indices:
					#print("setting fv ", fv_idx)
					#vol.face_vertices[fv_idx].color = color
				for fv in vol.face_vertices:
					if fv.face_index == f_idx:
						fv.color = color

		block.mesh_vector_data = vol.to_mesh_vector_data()
	builder.selection_changed.emit()


func undo_it():
#	print("undo_it() select faces")
	for block_path in block_map.keys():
		var rec:BlockFaceChanges = block_map[block_path]
		var block:CyclopsBlock = builder.get_node(block_path)
		block.mesh_vector_data = rec.tracked_block_data

	builder.selection_changed.emit()
	
