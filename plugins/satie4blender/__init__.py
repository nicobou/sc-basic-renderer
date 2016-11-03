# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

bl_info = {
    "name": "SATIE OSC",
    "author": "Michal Seta",
    "version": (0, 1, 1),
    "blender": (2, 75, 0),
    "location": "View 3D > Tool Shelf > SATIE panel",
    "warning": "Early stages of development",
    "wiki_url": "https://github.com/djiamnot/SATIE-OSC",
    "description": "Author SATIE audio scenes with Blender",
    "category": "User",
}

if "bpy" in locals():
    import imp
    imp.reload(panel)
else:
    from . import panel

import bpy

# class ToolsPanel(bpy.types.Panel):
#     bl_label = "SATIE tool"
#     bl_space_type = "VIEW_3D"
#     bl_region_type = "TOOLS"
 
#     def draw(self, context):
#         self.layout.operator("hello.hello")

# bpy.utils.register_module(__name__)

def initialize():
    print("Initializing SATIE bridge")

def register():
    initialize()
    bpy.utils.register_module(__name__)
 
def unregister():
    bpy.utils.unregister_module(__name__)

if __name__ == "__main__":
    register()
