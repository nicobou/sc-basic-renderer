SATIE (Spatial Audio Toolkit for Immersive Environments)
--------------------------------------------------------

SATIE is an audio spacialization engine developed at Société des arts technologiques [SAT] (http://sat.qc.ca) for realtime rendering of dense audio scenes to large multi-channel loudspeaker systems. It is a lower-level audio rendering process that maintains a dynamic DSP graph which is created and controlled via OSC messages from an external process. SATIE’s modular development environment provides for optimized real-time audio scene and resource management. There is no geometry per se in SATIE, rather, SATIE maintains a DSP graph of source nodes that are accumulated to a single "listener", corresponding to the renderer’s output configuration (stereo and/or multi-channel).

Its aim is to facilitate using 3D space in audio music/audio composition and authoring and to play well with 3D audio engines (so far it has been used with Blender and Unity3D) and could also serve as volumetric audio spacialization addition to more traditional desktop DAW systems. 

SATIE is built with SuperCollider, an audio programming environment and language and is controlled via OSC. 

See examples/ directory for example applications using Unity3D (satie4unity) and via scripting (satieOSC)

How to Install supercollider with supernova on linux
----------------------------------------------------

git clone https://github.com/supercollider/supercollider.git
cd supercollider/
sudo apt-get install build-essential libqt4-dev libqtwebkit-dev \
    libjack-jackd2-dev libsndfile1-dev libasound2-dev libavahi-client-dev \
    libicu-dev libreadline6-dev libfftw3-dev libxt-dev libcwiid-dev \
    pkg-config cmake subversion
mkdir build
cd build
cmake ..
make -j8
sudo make install

Install sc-plugins (with vbap)
------------------------------
git clone  https://github.com/supercollider/sc3-plugins.git
cd sc3-plugins/
mkdir build
cd build
cmake -DSC_PATH=../../supercollider/ -DQUARKS=OFF -DSUPERNOVA=ON ..
make -j8 && sudo make install


Compiling SuperNova on OSX
---------------------------

Refer to instructions in the README_OSX.md file of the SuperCollider repository (https://github.com/supercollider/supercollider)
Making the SC3-Plugins was straightforward. But you must copy the all the SC3 supernova plugins into your built superCollider.app/Content/Resources/Plugins folder, so they will be seen. 
NOTE: make sure you have an Audio MIDI setup in which there are inputs and outputs defined


Using Satie
---------------------------
Release structure:

audiosources:  synthdef-style files defining sound sources
doc:         documentation
effects:    synthdef-style files defining effects sources
examples:   some example uses
projects:   directory for user projects
prototype
README.md
spatializers:   synthdef-style files defining sound sinks (listeners)
src:        Satie system files
protocols:  OSC protocols (two protocols are currently supported)
tests
utils:      diagnostics and other tools




