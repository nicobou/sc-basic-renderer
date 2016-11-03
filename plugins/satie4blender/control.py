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
from . import properties as props
from . import satie_synth as ss

def instanceHandler():
    synths = [obj.id for obj in props.synths]
    # print("############## synths #########", synths)
    visibleObjs = bpy.context.visible_objects 
    if len(visibleObjs) > 0:
        for o in visibleObjs:
            if o.useSatie:
                if len(o.satieID) > 0:
                    if o.satieID in synths:
                        # print("-- {} in synths, passing.........".format(o.satieID))
                        pass
                    else:
                        # print("acting on ", o.name)
                        props.synths.append(ss.SatieSynth(o, o.satieID, o.satieSynth))
                        # print("current synths", props.synths)
                else:
                    print("{}'s satie ID cannot be empty", o.name)
            else:
                if o.satieID in synths:
                    print(">>>>>> removing {} from {}".format(o.satieID, o.name) )
                    toRemove = [x for x in props.synths if x.id == o.satieID]
                    for i in toRemove:
                        i.deleteNode()
                        props.synths.remove(i)

#    print("<<<<<< synths ", props.synths)

def instanceCb(scene):
    instanceHandler()
    [synth.updateAED() for synth in props.synths]
    
def cleanCallbackQueue():
    if instanceCb in bpy.app.handlers.scene_update_post:
        bpy.app.handlers.scene_update_post.remove(instanceCb)

def getSatieSendCtl(self):
    # print(props.active)
    return props.active

def setSatieSendCtl(self, value):
    props.active = value
    # print(props.active)

def setSatieHP(self, value):
    print("HighPass ", self.satieID, value)
