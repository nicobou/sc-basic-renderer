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


// s.reboot; s.makeGui;
s.meter;
(
s.waitForBoot{

	// finding source directory
	~rootSrcPath = thisProcess.nowExecutingPath.dirname ++ "/..";
	(~rootSrcPath ++ "/src/*.scd").pathMatch.do({arg item; item.loadPaths});

	// creating a sc-basic-renderer
	~scbr = ~scbrMaker.value(~rootSrcPath);
	// loading source plugins
	~scbr.pluginLoader.loadAudioPlugins(~rootSrcPath ++ "/audiosources/*.scd");
	// see the loaded plugins in the console
	~scbr.pluginLoader.audioPlugins;
	// loading spatializer plugins
	~scbr.pluginLoader.loadSpatPlugins(~rootSrcPath ++ "/spatializers/*.scd");
	~scbr.pluginLoader.spatPlugins;
	// generating SynthDef that are going to be used,
	// here a PinkSin source spatialized by
	//   - a stereo panner (starting channel 0)
	//   - a monoSpat (starting channel 2)
	//~scbr.makeSynthDef(\fool, \PinkSin, [\stereoPanner, \monoSpat], [0, 2]);
	//~scbr.makeSynthDef(\string, \zkarpluck1, [\stereoPanner, \monoSpat], [0, 2]);
	~scbr.makeSynthDef(\string, \zkarpluck1, [\domeVBAP], [0]);
	~scbr.makeSynthDef(\pinksin, \PinkSin, [\domeVBAP], [0]);
	~scbr.makeSynthDef(\testtone, \testtone, [\domeVBAP], [0]);

	// be sure the synthDef is compiled on the server
	s.sync;

};  // s.waitForBoot
)

// ******************** usage with JITlib & ProxySpace *********************
(
// creating a global ParGroup for supernova
~group = ParGroup.new; // ~group.freeAll;
// creating a global ProxySpace
~prox = ProxySpace(s);
~prox.fadeTime = 2;
// the proxyspace is going to be embedded in the global pargroup
~prox.group = ~group;

//instance factory
~makeinstance = { | name = \out, p, src = \string |
	// ensuring not extra bus is allocated:
	// (must be the first reference of "name" in the proxyspace
	p[name].ar(0);
	p[name].source = src;
	^nil;
};
~cleaninstance = { | name = \out, p |
	p[name].release();
	// fadeTime must be higher than SATIE internal fadeTime:
	p.[name].clear(0.03);
	^nil;
};
// test per instance set and group set
~makeinstance.value(\test1, ~prox, \string);
~makeinstance.value(\test2, ~prox, \string);
~makeinstance.value(\test3, ~prox, \pinksin);
// change test3 source
~makeinstance.value(\test3, ~prox, \testtone);

// list ProxySpace internal proxies:
~prox.existingProxies;
~cleaninstance.value(\test3, ~prox);
~prox.existingProxies;

// per instance set
~prox[\test1].set(\gainDB, -30);
~prox[\test2].set(\gainDB, -30);
~prox[\test1].set(\t_trig, 1, \note, rrand(42,72), 1, 0.5);
~prox[\test2].set(\t_trig, 1, \note, rrand(42,72), 1, 0.5);
//group set
~group.set(\aziDeg, 90);
~group.set(\t_trig, 1);


// CPU load test
~groupCPU = ParGroup.new; // ~group.freeAll;
// creating a global ProxySpace
~proxCPU = ProxySpace(s);
~proxCPU.fadeTime = 0.02;
// the proxyspace is going to be embedded in the global pargroup
~proxCPU.group = ~groupCPU;

// play until all CPU are loaded (~70%)
// (no sound since string must be trigered)
~makeinstance.value((\test ++ rrand(0, 10000).asSymbol), ~proxCPU, \string);

// list ProxySpace internal proxies:
~proxCPU.existingProxies;

// triger each string sequentially
~seqtrig = Routine({ ~proxCPU.existingProxies.do({ |item|
		~proxCPU[item].set(
			\t_trig, 1,
			\note, rrand(42, 72), rrand(1, 2), rrand(0.1, 0.9));
		rrand(0.05, 0.1).wait;
	});});
~groupCPU.set(\gainDB, -30);
~seqtrig.play;
~seqtrig.stop;

// trig all once
~groupCPU.set(\gainDB, -45);
~groupCPU.set(\t_trig, 1);
~groupCPU.set(\t_trig, 1,
	\note, rrand(42, 72), rrand(1, 2), rrand(0.1, 0.9),
	\aziDeg, rrand(-180,180),
	\eleDeg, rrand(0,90));

~allTrig = Routine({ 1800.do({ |item|
	~groupCPU.set(\t_trig, 1,
		\note, rrand(42, 72), rrand(1, 2), rrand(0.1, 0.9));
	0.2.wait;
});});
~allTrig.play;

// change with gui
w=Window.new("sheefa", Rect(30, 30, 400, 100)).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=8@2;
h = EZSlider(w, 380@20, "azi", ControlSpec(-180, 180, \lin, 0.1, 0));
h.action_({ |ez| ( ~groupCPU.set(\aziDeg, (ez.value)))});
i = EZSlider(w, 380@20, "elev", ControlSpec(-90, 90, \lin, 0.1, 0));
i.action_({ |ez| ( ~groupCPU.set(\eleDeg, (ez.value)))});
j = EZSlider(w, 380@20, "spread", ControlSpec(0, 100, \lin, 0.1, 5));
j.action_({ |ez| ( ~groupCPU.set(\spread, (ez.value)))});



)

// ****************** usage with synth creation ************************
(

// initialization is done, create and remove a source + controls
g = Synth.head(s, \fool, [\spread,0]);

// spat properties
g.set(\gainDB, -30);
g.set(\aziDeg, rrand(-180, 180));
g.set(\eleDeg, 90);
g.set(\spread, 0);
g.set(\lfoHz, 10);

// source properties
g.set(\sfreq, rrand(200, 400));

// CPU load test
// creating a global ParGroup for supernova
~groupCPU = ParGroup.new; // ~group.freeAll;
r = Routine({
	loop {
		Synth.head(~groupCPU, \string);
		0.1.wait;
}});
// play until all CPU are loaded (~70%)
// (no sound since string must be trigered)
r.play;
r.stop;

// trig all once
~groupCPU.set(\gainDB, -45);
~groupCPU.set(\t_trig, 1,
	\note, rrand(42, 72), rrand(1, 2), rrand(0.1, 0.9),
	\aziDeg, rrand(-180,180),
	\eleDeg, rrand(0,90));
)
