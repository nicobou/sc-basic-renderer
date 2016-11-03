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

import bpy
from . import control

# print("Panel loaded")

class ToolsPanel(bpy.types.Panel):
    bl_label = "SATIE tool"
    bl_context = "objectmode"
    bl_category = "SATIE"
    bl_space_type = "VIEW_3D"
    bl_region_type = "TOOLS"
    bl_options = {'DEFAULT_CLOSED'}

    def draw_header(self, context):
        layout = self.layout
        layout.label(text='', icon='SPEAKER')
    
    def draw(self, context):
        layout = self.layout
        layout.label("SATIE connection")
        
        row = layout.row()
        # row.prop(context.object, "useSatie")
        # row.prop(context.scene, "active")

        row = layout.row()
        row.prop(context.scene, "SatieSources")
        row = layout.row()
        row.operator("mesh.satie_sound").active = True


class SatieProperties(bpy.types.Panel):
    bl_space_type = "PROPERTIES"
    bl_region_type = "WINDOW"
    bl_context = "object"
    bl_label = "SATIE properties"
#    def draw(self, context) :
#        TheCol = self.layout.column(align = True)
#        TheCol.prop(context.scene, "make_satie_properties")
#        TheCol.operator("mesh.add_satie_properties", text = "SATIE properties")
#        TheCol.prop(self, "useSatie")
#        TheCol.prop(self, "satieID")
 
    def draw(self, context) :
        objs = context.selected_objects
        if len(objs) is not 1:
            self.layout.label('Select exactly ONE object')
        else:
            TheCol = self.layout.column(align = True)
            #TheCol.prop(context.scene, "make_satie_properties")
            #TheCol.operator("mesh.add_satie_properties", text = "SATIE properties")
            TheCol.prop(context.object, "useSatie")
            TheCol.prop(context.object, "satieID")
            TheCol.prop(context.object, "satieSynth")
            TheCol.prop(context.object, "satieGroup")
            TheCol.prop(context.object, "hiPass")
            TheCol.prop(context.object, "loPass")
            # TheCol.prop(context.object, "sendToSATIE")
            # TheCol.prop(context.object, "state")

class SatieObject(bpy.types.Operator):
    bl_idname = "mesh.satie_sound"
    bl_label = "SATIE sound source"
    bl_options = {"REGISTER", "UNDO"}
    fcount = 0
    active = bpy.props.BoolProperty()

    # def __init__(self):
    #     print("init in SatieObject")
    
    def execute(self, context):
        # print("Satie synth interface instantiated")
        if self.active:
            if control.instanceCb not in bpy.app.handlers.scene_update_post:
                bpy.app.handlers.scene_update_post.append(control.instanceCb)
        else:
            if control.instanceCb in bpy.app.handlers.scene_update_post:
                control.cleanCallbackQueue()
        # else:
        #     bpy.app.handlers.scene_update_post.remove(instanceCb)
        # if exeCallback not in bpy.app.handlers.scene_update_post:
        #     bpy.app.handlers.scene_update_post.append(exeCallback)
        # else:
        #     bpy.app.handlers.scene_update_post.remove(exeCallback)
        return {'FINISHED'}

    def getSatieID(self):
        print(bpy.context.object.satieID)



def initObjectProperties():
    # print("********************************************* properties **************************************")
    bpy.types.Object.useSatie = bpy.props.BoolProperty(
        name = "Use SATIE",
        description = "Assign this object a SATIE sound source",
        default = False
    )
    bpy.types.Object.satieID = bpy.props.StringProperty(
        name = "ID",
        description = "Sound source ID",
        default = ""
    )
    bpy.types.Object.satieSynth = bpy.props.StringProperty(
        name = "Sound source",
        description = "SATIE plugin to use",
        default = "tastee"
    )
    bpy.types.Object.satieGroup = bpy.props.StringProperty(
        name = "Group",
        description = "instrument/FX group",
        default = "default"
    )
    bpy.types.Object.sendToSATIE = bpy.props.BoolProperty(
        name = "Send to SATIE",
        description = "(Un)mute the SATIE instance",
        default = False
    )
    bpy.types.Object.state = bpy.props.BoolProperty(
        name = "Source playing state",
        description = "Playing state (on, off)",
        default = False
    )

    bpy.types.Object.hiPass = bpy.props.FloatProperty(
        name = "High pass",
        description = "High pass filter",
        default = 0.5,
        set = control.setSatieHP
    )
    bpy.types.Object.loPass = bpy.props.FloatProperty(
        name = "Low pass",
        description = "Low pass filter",
        default = 15000.00
    )

    bpy.types.Scene.active = bpy.props.BoolProperty(
        name = "Use Satie",
        description = "Activate SATIE communication",
        default = False,
        set = control.setSatieSendCtl,
        get = control.getSatieSendCtl
    )

    bpy.types.Scene.SatieSources = bpy.props.EnumProperty(
        items = [],
        name = "Sources")


# satieObject = SatieObject()
    
# bpy.utils.register_class(SatieObject)
# bpy.ops.mesh.satie_sound()

initObjectProperties()
# print("******************* PANEL executed ***********************")

