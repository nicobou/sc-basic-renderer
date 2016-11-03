// reads soundfiles into sound buffers using same names
// this file must be evaluated AFTER main.scd and projectName.scd


//~aqSoundDir="~/".standardizePath ++"Dropbox/Unity3D/projects_unity5/aquaKhoriaShow/Assets/StreamingAssets/sound";

~autoLoadDirCmd = "ls "++~aqSoundDir++"/*.wav "++~aqSoundDir++"/*.aiff "++~aqSoundDir++"/*.aif 2>/dev/null";



~pipe = Pipe.new(~autoLoadDirCmd, "r");            // list directory contents in long format

~files =List.new();
~done = nil;
while (  { ~done != true} ,
	{
		var filePath;
		filePath = ~pipe.getLine;

		if ( filePath != nil,
			{
				~files.add( filePath);
			},
			// else
			{
				~done = true;
		});
});
~pipe.close;



//  if not defined, create list of  sound buffers
if (~aqPlayBuffers == nil,
	{
		~aqPlayBuffers = Dictionary();

	},
	// else
	{
		inform("loadSamps: ~aqPlayBuffers already defined, no need to allocate");
});


s.waitForBoot {


	~files.do { |f|
		var sfName =  f.split.last;
		var sfType = "normal";



		if (~aqPlayBuffers.at(sfName.asSymbol) == nil,
			{
				inform("buffering: "++sfName);
			// generate sample  buffer
				~aqPlayBuffers.add(sfName.asSymbol -> Buffer.read(s, f));
		});

		// special treatment for samples with specfic rootNames: e.g. "drop"

		if (sfName.containsi("drop"), {sfType = "drop"});
		if (sfName.containsi("iceCave6chAcc"), {sfType = "syncSampZombies"});
		if (sfName.containsi("3ch"), {sfType = "3chLooper"});
		if (   (  sfName.containsi("6ch") && sfName.containsi("Whale") )  , {sfType = "6chLoopBuff"});
		if (sfName.containsi("vortex"), {sfType = "sndBuff2"});
		if (sfName.containsi("Gull"), {sfType = "sndBuff2"});

		switch (sfType,

			"drop",   { ~scbr.makeSynthDef2(sfName.asSymbol++'\:k:rev', \zPsamp1,  [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, [~aqPlayBuffers[sfName.asSymbol].bufnum]); }, //  for kamakazis with no clones

			"syncSampZombies", {
				inform("loadSamps: MAKING makeSynthDef2 name:"++sfName.asSymbol++'\:k');

				~scbr.makeSynthDef2(sfName.asSymbol++'\:k', \syncSamp1,  [], [~listeningFormat],  [0], \defaultMapper, [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				~scbr.makeSynthDef2(sfName.asSymbol++'\:k:rev', \syncSamp1,  [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				//~scbr.makeSynthDef(sfName.asSymbol, \syncSamp1, [~listeningFormat], [0],  [], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				//~scbr.makeSynthDef(sfName.asSymbol++'\:rev', \syncSamp1, [~listeningFormat], [0],  [~scbr.aux[~inBus0]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
			}, //  for kamakazis with no clones

			"3chLooper", {
				inform("loadSamps: MAKING makeSynthDef(s) for name:"++sfName.asSymbol);

				// no reverb version
				~scbr.makeSynthDef(sfName.asSymbol,   "3chLooper".asSymbol  , [~listeningFormat], [0],  [], [~aqPlayBuffers[sfName.asSymbol].bufnum]);

				// version with  rev send, referenced by   pluginName:rev  inbus N
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev',  "3chLooper".asSymbol     , [~listeningFormat], [0],  [~scbr.aux[~inBus0]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev1',  "3chLooper".asSymbol     , [~listeningFormat], [0],  [~scbr.aux[~inBus1]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
			},
			"6chLoopBuff", {
				inform("loadSamps: MAKING makeSynthDef(s) for name:"++sfName.asSymbol);

				// no reverb version
				~scbr.makeSynthDef(sfName.asSymbol,   "6chLoopbuff".asSymbol  , [~listeningFormat], [0],  [], [~aqPlayBuffers[sfName.asSymbol].bufnum]);

				// version with  rev send, referenced by   pluginName:rev  inbus N
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev',  "6chLoopbuff".asSymbol     , [~listeningFormat], [0],  [~scbr.aux[~inBus0]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev1',  "6chLoopbuff".asSymbol     , [~listeningFormat], [0],  [~scbr.aux[~inBus1]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
			},


			"normal",  {

				//postf("FX buffer at: %", ~scbr.aux[~inBus0]);

				// create sample buffer playback with no rev send
				~scbr.makeSynthDef(sfName.asSymbol, \sndBuffer, [~listeningFormat], [0],  [], [~aqPlayBuffers[sfName.asSymbol].bufnum]);

				// create sample buffer playback with  rev send, referenced by   pluginName:rev
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev', \sndBuffer, [~listeningFormat], [0],  [~scbr.aux[~inBus0]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev1', \sndBuffer, [~listeningFormat], [0],  [~scbr.aux[~inBus1]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
			},
			"sndBuff2", {

				//postf("FX buffer at: %", ~scbr.aux[~inBus0]);

				// create sample buffer playback with no rev send
				~scbr.makeSynthDef(sfName.asSymbol, \sndBuffer2, [~listeningFormat], [0],  [], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
				~scbr.makeSynthDef(sfName.asSymbol++'\:rev', \sndBuffer2, [~listeningFormat], [0],  [~scbr.aux[~inBus0]], [~aqPlayBuffers[sfName.asSymbol].bufnum]);
			}


		);


		//postf("CREATING SYNTHDEF: : %\n", sfName.asSymbol++'\:rev');

	};

}


/*  test
g = "myNoise_CaveWater_track01.0.M.wav".asSymbol
~scbr.makeInstance(\sheefa, g, \default);
~scbr.satieGroupInstances[\default][\sheefa].set(\gainDB, -30, \loop, 1);
~scbr.satieGroupInstances[\default][\sheefa].set(\gainDB, -99, \loop, 0);
*/



