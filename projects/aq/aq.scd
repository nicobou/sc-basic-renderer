//~satie4unity=nil;

// called from project's  main.scd file

//WAS ~aqSoundDir="~/".standardizePath ++"Dropbox/Unity3D/projects_unity5/aquaKhoriaShow/Assets/StreamingAssets/sound";

~aqSoundDir="~/".standardizePath ++"src/aquakhoria/AquaKhoria_UnityProject/Assets/StreamingAssets/sound";

s.waitForBoot{

	~num_aux_bus = 5;  // THIS MUST BE DEFINED FOR PROJECTS, with a value of 1 or greater


	// based on the value of ~num_aux_bus,  the following can be defined
	~inBus0 = 0;  // relative aux bus number that satie will use for this project's synthdef sends to fx synthdefs
	~inBus1 = 1;  // relative aux bus number that satie will use for this project's synthdef sends to fx synthdefs
	~inBus2 = 2;  // relative aux bus number that satie will use for this project's synthdef sends to fx synthdefs
	~inBus3 = 3;  // relative aux bus number that satie will use for this project's synthdef sends to fx synthdefs
	~inBus4 = 4;  // relative aux bus number that satie will use for this project's synthdef sends to fx synthdefs


	// create and initialize a sc-basic-renderer, and set environment variable
	if (~scbr == nil,{
		postln("loading SATIE kernal...");
		~scbr = ~scbrMaker.value(numAudioAux: ~num_aux_bus, satieSrcPath: ~rootSrcPath);
	});


	s.sync;

	// define the phasorSync Generator, used by the syncSamp1 synthdef
	if (~phasorSync == nil,
			{
		"creating phasorSync generator".inform;
			~phasorSync = Synth.before(s,\globalPhasor);
	});

		// required
	~scbr.makeSynthDef(\dummyPlugin, \emptySource, [\emptySpat], [0]);    // dummy synthdef, used for new nodes - required for all projects


	//  declare all the project's needed synthDefs here
	postf("generating example project synthdefs for % format \n", ~listeningFormat);
	~scbr.makeSynthDef(\zparticle1, \zparticle1, [~listeningFormat], [0]);
	~scbr.makeSynthDef(\pink, \PinkSin, [~listeningFormat], [0]);
	~scbr.makeSynthDef(\dust, \DustDust, [~listeningFormat], [0]);
	~scbr.makeSynthDef(\default, \default, [~listeningFormat], [0], [~scbr.aux[~inBus0]]);
	~scbr.makeSynthDef(\zkarpluck0, \zkarpluck0, [~listeningFormat], [0]);
	//~scbr.makeSynthDef(\zkarpluck1, \zkarpluck1, [~listeningFormat], [0]);
	~scbr.makeSynthDef(\test, \testtone,  [~listeningFormat], [0]);
	//~scbr.makeSynthDef(\zbell1, \zbell1, [~listeningFormat], [0]);

	~scbr.makeSynthDef(\pbell1, \pbell1, [~listeningFormat], [0]);
	// same thing but with with reverb send
	~scbr.makeSynthDef(\pbell1++'\:rev', \pbell1, [~listeningFormat], [0], [~scbr.aux[~inBus0]]);

	~scbr.makeSynthDef(\zkarpluck1, \zkarpluck1, [~listeningFormat], [0]);
	// same thing but with with reverb send
	~scbr.makeSynthDef(\zkarpluck1++'\:rev', \zkarpluck1, [~listeningFormat], [0], [~scbr.aux[~inBus0]]);

	// effects node
	~scbr.makeSynthDef(\busreverb, \freeverb, [~listeningFormat], [0]);
	~scbr.makeSynthDef(\busgverb, \gverb, [~listeningFormat], [0]);

	// note order:   name, synthName, fxBus, listenerName, outBusNo, mapName, optArgs
	~scbr.makeSynthDef2(\zkarpluck1P, \zkarpluck1P,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \randOffsets1, []);   // for kamikazis
	~scbr.makeSynthDef2(\zkarpluck2P, \zkarpluck2P,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \randOffsets1, []);  // for resonant updated klones
    ~scbr.makeSynthDef2(\zkarpluck3P, \zkarpluck2P,   [], [~listeningFormat],  [0], \defaultMapper, []);  //  for kamakazis with no clones
    ~scbr.makeSynthDef2(\zkarpluck3P++'\:rev', \zkarpluck2P,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, []);  //  for kamakazis with no clones
   ~scbr.makeSynthDef2(\zkarpluck3P++'\:rev1', \zkarpluck2P,   [~scbr.aux[~inBus1]], [~listeningFormat],  [0], \defaultMapper, []);  //  for kamakazis with no clones




//~scbr.makeSynthDef2(\particule1, \particule1,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, []);  //  for kamakazis
	~scbr.makeSynthDef2(\particule1, \particule1,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, []);  //  for kamakazis
	// ~scbr.makeSynthDef2(\particule1, \particule1,   [~scbr.aux[~inBus0]], [\labodomeVBAP],  [0], \defaultMapper, []);  //  for kamakazis
	~scbr.makeSynthDef2(\particule1dyn, \particule1dyn,   [~scbr.aux[~inBus0]], [~listeningFormat],  [0], \defaultMapper, []);  //  for allocated staticlly spatialized particles


// - load soundfiles done automatically in the loadSamps file




	// be sure the synthDef is compiled on the server

	s.sync;

	// instantiate the OSC interface
	if (~oscInterface == nil,{
		~oscInterface = ~spatOSCMaker.value();
	});
	// instiante the satie4Unity protocol
	if (~satie4unity == nil,{
		~satie4unity = ~satie4unityprotocol.value(~oscInterface, ~scbr);
		~satie4unity.projectDirectory = "~/src/aquakhoria/AquaKhoria_UnityProject/Assets/StreamingAssets"     // PROJECT SPECIFIC DEFAULT  CAN BE SET AND THEN OVERWRITTEN BY SATIE SCRIPTS IN UNITY PROJECT
	});
	s.sync;

	// PROJECT SPECIFIC OSC MESSAGES

~aquakhoriaCallback = {
	arg msg;
	var command = msg[1];
	postf("~aquakhoriaCallback: command: %, msg: %, \n", command, msg);

	if (msg.size < 2,
		{"~aquakhoriaCallback: empty message".warn;
			postf("~basicRendererCallback MESS LEN: %", msg.size);

		},
		// else
		{

			switch (command,
				'resetSync',
				{
					if (~phasorSync != nil,
						{
							"resetting phasorSync generator".inform;
							~phasorSync.set(\t_trig, 1);
					});

				},

			/*	,
				'setOutputTrimDB',
				{
					if ( (msg.size < 3 ) ,
						{"~aquakhoriaCallback: setOutputTrimDB missing value".warn;},
						// else
						{
							//e.outputTrimDB = msg[2];
							//e.volume.volume = e.outputTrimDB + e.outputDB;
						}
					)
				},
				*/

			)
	});
};


// CONNECT TO OSC USING BASIC RENDERER SETTINGS (PORT ETC.)
~oscInterface.removeBasicRendererOSC(\aquakhoria);

~oscInterface.newOSC(\aquakhoria, ~aquakhoriaCallback, "/satie/aquakhoria");
};  // end of  waitforboot






/*
testing

~myFile =  "/Users/zack/Dropbox/Unity3D/projects_unity5/balljamDemoSATIE_2015_unity5/Assets/StreamingAssets/midi/pitchSequences/bjGroove.mid.mid.txt";
~sheefa.readPitches(~myFile);
~sheefa.pitchSeqLen;
~sheefa.pitchSeqName;

*/
