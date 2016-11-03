// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// This file is loaded by main.scd in the same directory

// finding source directory

(
Server.supernova;
o = Server.local.options;
o.numOutputBusChannels = 32;
o.memSize = 2**20;
o.blockSize = 2048;
//s.reboot;
s.makeGui;
s.meter;
s.plotTree;
s.waitForBoot {
	~rootSrcPath = thisProcess.nowExecutingPath.dirname ++ "/../..";
	(~rootSrcPath ++ "/src/*.scd").pathMatch.do({arg item; item.loadPaths});

	~num_aux_bus = 5;
	// creating a sc-basic-renderer
	~scbr = ~scbrMaker.value(numAudioAux: ~num_aux_bus, satieSrcPath: ~rootSrcPath);
	// printing internal aux array with bus indexes
	// ~scbr.aux;
	// ~scbr.auxbus.scope;

	// generating SynthDef that are going to be used,
	// here a PinkSin source spatialized by
	//   - a stereo panner (starting channel 0)
	//   - a monoSpat (starting channel 2)
	~scbr.makeSynthDef(\fool, \PinkSin, [\octoVBAP, \monoSpat], [0, 2]);

	//~scbr.makeSynthDef(\string, \zkarpluck1, [\stereoPanner, \monoSpat], [0, 2]);
	~scbr.makeSynthDef(\string, \zkarpluck1, [\stereoPanner], [0]);
	~scbr.makeSynthDef(\pinksin, \PinkSin, [\quadVBAP], [0]);
	// generate a synth and change its defaults
	~scbr.makeSynthDef(\pink400, \PinkSin, [\stereoPanner], [0], [], [800]);

	~scbr.makeSynthDef(\testtone, \testtone, [\domeVBAP], [0]);
	// writing to all aux busses (first is starting a 0):
	~scbr.makeSynthDef(\string_all_aux, \zkarpluck1, [\stereoPanner], [0], ~scbr.aux);
	// writing to only to the third audio bus
	~scbr.makeSynthDef(\string_third_aux, \zkarpluck1, [\stereoPanner], [0], [~scbr.aux[2]]);
	// spatilized reverb effect (input will be set at creation):
	~scbr.makeSynthDef(\busreverb, \freeverb, [\stereoPanner], [0]);
	// mono input
	~scbr.makeSynthDef(\monoIn, \MonoIn, [\stereoPanner], [0]);
	~scbr.makeSynthDef(\tastee, \testee, [\domeVBAP, \stereoPanner], [0]);
	~scbr.makeSynthDef(\drone, \misDrone, [\domeVBAP, \stereoPanner], [0]);
	// streaming a soundfile from disk
	// - load soundfiles
	~playBuffers = Dictionary();
	~playBuffers.add(\bleh -> Buffer.cueSoundFile(s, Platform.resourceDir +/+ "sounds/a11wlk01.wav", 0, 1));
	~playBuffers.add(\alsaTest -> Buffer.cueSoundFile(s, "/usr/share/sounds/alsa/Front_Center.wav", 0, 1));
	// create players
	~scbr.makeSynthDef(\snd1, \sndFile, [\stereoPanner], [0], [], [~playBuffers[\bleh].bufnum]);
	~scbr.makeSynthDef(\snd2, \sndFile, [\stereoPanner], [0], [], [~playBuffers[\alsaTest].bufnum]);
	// be sure the synthDef is compiled on the server
	~osc = ~satieOSCMaker.value(port: 18032);
	~newOsc = ~satieOSCMaker.value(port: 18034);
	s.sync;
	(~rootSrcPath ++ "/protocols/satieOSC.scd").load;
	s.sync;
	~oscOne = ~satieOSCprotocol.value(~osc, ~scbr, oscID: \satieStandard);
	~osc2 = ~satieOSCprotocol.value(~newOsc, ~scbr);
	s.sync;
};
)

~osc2.createSoundSource(\boo);
