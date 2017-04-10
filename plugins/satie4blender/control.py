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
    visibleObjs = bpy.context.visible_objects 
    if len(visibleObjs) > 0:
        for o in visibleObjs:
            if o.useSatie:
                if len(o.name) > 0:
                    if o.name in synths:
                        pass
                    else:
                        print("acting on ", o.name, o.satie_synth)
                        props.synths.append(ss.SatieSynth(o, o.name, o.satie_synth))
                else:
                    print("{}'s satie ID cannot be empty", o.name)
            else:
                if o.name in synths:
                    print(">>>>>> removing {} ".format(o.name) )
                    toRemove = [x for x in props.synths if x.id == o.name]
                    for i in toRemove:
                        i.deleteNode()
                        props.synths.remove(i)

def satieInstanceCb(scene):
    instanceHandler()
    [synth.updateAED() for synth in props.synths]
    
def cleanCallbackQueue():
    if satieInstanceCb in bpy.app.handlers.scene_update_post:
        bpy.app.handlers.scene_update_post.remove(satieInstanceCb)

def getSatieSendCtl(self):
    return props.active

def setSatieSendCtl(value):
    props.active = value
    print(props.active)

def setSatieHP(self, value):
    print("HighPass ", self.name, value)

def setInputBus(self, value):
    print("setInputBus called", self.name, self.bus)
    synths = [obj.id for obj in props.synths]
    print("we got the following synths: ", synths)
    if self.name in synths:
        toSet = [s for s in props.synths if s.id == self.name]
        for s in toSet:
            s.set('bus', int(self.bus))
        
def setInputBus(self, value):
    print("setInputBus called", self.name, self.bus)
    synths = update_synths()
    print("we got the following synths: ", synths)
    if self.name in synths:
        toSet = [s for s in props.synths if s.id == self.name]
        for s in toSet:
            s.set('bus', int(self.bus))
        
def setOSCdestination(self, context):
    print ("setting host to ", context.scene.OSCdestination)
    destination = context.scene.OSCdestination
    props.destination = destination

def setOSC_destination_port(self, context):
    port = context.scene.OSC_destination_port    
    props.satie_port = port

def setOSC_server_port(self, context):
    port = context.scene.OSC_server_port    
    props.server_port = port

def set_param(name, param, value):
    synths = update_synths()
    if name in synths:
        toSet = [s for s in props.synths if s.id == name]
        for s in toSet:
            s.set(param, value)
    

def update_synths():
    return [obj.id for obj in props.synths]
