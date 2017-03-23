#!/bin/bash


#BASIC_TEST=1
#PLUCK_TEST=1
GROUP_TEST=1
#PROCESSING_TEST=1

OSCPORT=18032


# will create a node using the "default" plugin
clear

if [ $BASIC_TEST ] ; then

clear;
echo TESTING BASIC SATIE4UNITY COMMANDS
sleep 2

echo CREATE SOURCE NODE mySound
oscsend localhost $OSCPORT /satie/scene createSource mySound plugin://default
sleep 2

echo PAN HARD LEFT
oscsend localhost $OSCPORT /satie/source/update sfffffff mySound -90 -12 0 22050 0.5  10 # azi ele  gainDB del lpf distance
sleep 1

oscsend localhost $OSCPORT /satie/source/update sfffffff mySound 90 0 3 0 22050 0.5  10 # azi ele  gainDB del lpf distance
echo PAN HARD RIGHT, GAIN = 3db
sleep 1

oscsend localhost $OSCPORT /satie/source/update sfffffff mySound 0 0 0 0 22050 0.5  10 # azi ele  gainDB del lpf distance
echo PAN CENTER, GAIN = 0db
sleep 1

oscsend localhost $OSCPORT /satie/source/update sfffffff mySound -45 0 -16 0 1000 0.5  10 # azi ele  gainDB del lpf distance
echo PAN LEFT. GAIN = -16db LPF = 1000
sleep 1

oscsend localhost $OSCPORT /satie/source/update sfffffff mySound 0 0 -6 0 22050 0.5  10 # azi ele  gainDB del lpf distance
echo PAN CENTER, GAIN = -6, LPF = 22050
sleep 1

oscsend localhost $OSCPORT /satie/source/update sfffffff mySound 45 0 -24 0 22050 0.1  10 # azi ele  gainDB del lpf distance
echo  PAN RIGHT, GAIN = -24db
sleep 1

oscsend localhost $OSCPORT /satie/source/set  ssf mySound spread 0
echo  SPREAD WIDE
sleep 1

oscsend localhost $OSCPORT /satie/source/set  ssf mySound  spread 2
echo  SPREAD NARROW
sleep 1

oscsend localhost $OSCPORT /satie/source/set  ssf mySound  spread 1
echo  SPREAD NORMAL
sleep 1

oscsend localhost $OSCPORT /satie/source/set  ssf mySound  state 0
echo  STATE = 0
sleep 1

oscsend localhost $OSCPORT /satie/source/set  ssf mySound  state 1
echo  STATE = 1
sleep 1

oscsend localhost $OSCPORT /satie/source/set ssf mySound lfoHz 3
echo  param:  lfoHz = 3
sleep 1

oscsend localhost $OSCPORT /satie/source/set ssf mySound lfoHz 20
echo  param:  lfoHz = 20
sleep 1

oscsend localhost $OSCPORT /satie/source/set ssf mySound lfoHz 2
echo  param:  lfoHz = 2
sleep 2

oscsend localhost $OSCPORT /satie/scene ss deleteNode mySound
echo  DELETE NODE SHEEFA
echo done
fi

if [ $PLUCK_TEST ] ; then

echo TESTING PLUCK
oscsend localhost $OSCPORT /spatosc/scene sss createSource mySound plugin://zkarpluck1
sleep 1

oscsend localhost $OSCPORT /satie/source/setvec ssff mySound note  76 .5 1
echo  SET NOTE VALUES: 76 .5 1 :  midiPitch  amp vel
oscsend localhost $OSCPORT /satie/source/set ssf mySound t_trig 1
echo  TRIGGER:  t_trig 1
sleep 1

oscsend localhost $OSCPORT /satie/source/set ssf mySound c3 1
echo  param:  c3 = 1
oscsend localhost $OSCPORT /satie/source/setvec ssff mySound note  72 .5 1
echo  SET NOTE VALUES: 72 .5 1 :  midiPitch  amp vel
oscsend localhost $OSCPORT /satie/source/set ssf mySound t_trig 1
sleep 1

oscsend localhost $OSCPORT /satie/source/set ssf mySound c1 5
echo  param:  c1 = 5
oscsend localhost $OSCPORT /satie/source/set ssf mySound fb 90
echo  param:  fb = 90
oscsend localhost $OSCPORT /satie/source/setvec ssff mySound note  78 .9 .8
echo  SET NOTE VALUES: 78 .9 .8 :  midiPitch  amp vel
oscsend localhost $OSCPORT /satie/source/set ssf mySound t_trig 1
sleep 4


oscsend localhost $OSCPORT /spatosc/scene s clear
echo clearing scene

fi



if [ $GROUP_TEST ] ; then

clear
echo TESTING GROUP
echo creating group node and three source nodes

oscsend localhost $OSCPORT /satie/scene ss createGroup pluckGroup
oscsend localhost $OSCPORT /satie/scene ssss createSource source1 "plugin://zkarpluck1" pluckGroup
oscsend localhost $OSCPORT /satie/scene ssss createSource source2 "plugin://zkarpluck1" pluckGroup
oscsend localhost $OSCPORT /satie/scene ssss createSource source3 "plugin://zkarpluck1" pluckGroup
sleep .5
oscsend localhost $OSCPORT /satie/group/set ssf pluckGroup gainDB 0
echo setting group gainDB to 0
sleep .5
echo triggering notes

oscsend localhost $OSCPORT /satie/source/setvec ssff source1 note 65 1 1
sleep .3

oscsend localhost $OSCPORT /satie/source/setvec ssff source2 note 69 1 1
sleep .3

oscsend localhost $OSCPORT /satie/source/setvec ssff source3 note 72 1
sleep 3


oscsend localhost $OSCPORT /satie/scene s clear

echo done

fi


if [ $PROCESSING_TEST ] ; then

clear
echo TESTING PROCESSING_NODE
oscsend localhost $OSCPORT /satie/scene s clear
sleep 2

oscsend localhost $OSCPORT /satie/scene sss createSource pNode1 "process://sheefa"
oscsend localhost $OSCPORT /satie/scene sss connect pNode1 ear
oscsend localhost $OSCPORT /satie/source/pNode1/event sffff setup 10 20 10 1    #cloneCount randAzi randElev randDist
sleep 1
oscsend localhost $OSCPORT "/spatosc/core/connection/pNode1->ear/update" fffff -1.57 0 -12 0 22050  # azi ele  gainDB del lpf
echo PAN LEFT
sleep .5
oscsend localhost $OSCPORT "/spatosc/core/connection/pNode1->ear/spread" f 10  # spread value
sleep .5
oscsend localhost $OSCPORT /satie/source/pNode1/event ssf setParam cloneCount 33    #set a value in the process
echo SET PROCESS PROPERTY
sleep .5
oscsend localhost $OSCPORT /satie/source/pNode1/prop sf hpfq 4000
sleep .5
echo SET SYNTH NAME
oscsend localhost $OSCPORT /satie/source/pNode1/event sss setParam synthName zkarpluck1
sleep .5
echo TRIGGER
oscsend localhost $OSCPORT /satie/source/pNode1/event s trigger




echo done

fi





















