

// note this class acts on synthdefs that do not have array args.


// this file defines  a process class, which is ONLY used by source nodes that have that have a URI of type:   "process" , e.g:      uri://process  "particuleAlloc1"
// you can define any number of these process clases, each one, corresponding to a particular type of processing  behavoir you define

// this class is for preallocated klones with no spatializer updates (except for the one at trigger time)

// required:  set up class struct

~particuleAlloc1 = Environment[
	// required fields
	'nodeName' -> \nil,
	'nodeGroupName' -> \nil,
	'nodeGroup' -> \nil,


	// project specific
	//'voiceVector' -> [],  // vector to store allocated synths
	'synthName' -> \default,  // \zparticle2P,
	'voiceCount' -> 10,    // number of voices to allocate  (times voices)
	'voicePool' -> 0,   // will be = to voiceCount synth voices
	'cloudRadius' -> 5, // NOT IMPLEMENTED
	'cloudExp'-> 2,    // increase this value to make cloud more "narrow"  (narrows more quickly as with distance)
	'triggerIntervalMs' -> 500,   // time interval, during which the voices will randomly trigger
	// other state
	'transposition' -> 0,
	'pitchSeqGlobalMode' -> 0,
	'pitchSeqSym' -> \default,
	'pitchSeqLen' -> 1,   // not used
	'pitchSeqIncr' -> 1,   // used, but only to set global sequencer state
	'pitchSeqPos' -> 0,     // not used
	// playback state
	'voicePtr' -> 0,    // modulus voice playing pointer
];


// required: set these variables to the process name;
~processName = \particuleAlloc1;
~process = ~particuleAlloc1;
~process.know=true;

if (~satie4unity == nil, {
	error(~processName ++ ": ~satie4unity protocol undefined, can't register this process");
}, // else
{
	// if already registered, re-register
	if (  ~satie4unity.allProcesses.includesKey(~processName) == true,
		{
			inform("un-registering process: "++~processName);
			~satie4unity.allProcesses.removeAt(~processName);
	});

	inform("registering process: "++~processName);
	~satie4unity.allProcesses.put(~processName, ~process);
});



// set up class instance dictionary

~particuleAlloc1_instances = Dictionary.new();

// define any custom "class"  variables, referenced by all "instants"  of "particuleAlloc1" class
if (~particuleAlloc1_pitchSequences == nil,
	{
		~particuleAlloc1_pitchSequences = Dictionary.new();
		~particuleAlloc1_pitchSequences.put(\default, Dictionary.new());
		~particuleAlloc1_pitchSequences.at(\default).put(\pitches, [60]);
		~particuleAlloc1_pitchSequences.at(\default).put(\pos, 0);
		~particuleAlloc1_pitchSequences.at(\default).put(\incr,1);
		~particuleAlloc1_pitchSequences.at(\default).put(\size,1);

});

// required functions

~particuleAlloc1.cleanup = { | self |

	var synth;

	// add code here to manage project-specific stuff
	postf("~particuleAlloc1.clearSynths: clearing synths in node: % group \n", self.nodeName);
	self.voicePool.do( { arg item;
		var nodename=(self.nodeName++"_"++item).asSymbol;
		~scbr.cleanInstance(nodename.asSymbol, self.nodeGroupName);
	});
	~particuleAlloc1_instances.removeAt(self.nodeName);
};


// required function but adaptable to project specifics
// generates N synths

// optional args:  (order important):    voiceCount, synthName
~particuleAlloc1.setup = { | self, nodeName, nodeGroupName, argsList  |
	var thisGroup = ~scbr.satieGroups[nodeGroupName.asSymbol] ;

	self.nodeName = nodeName;
	self.nodeGroupName = nodeGroupName;
	self.nodeGroup = thisGroup;
	//'particuleAlloc1,setup'.postln;

	// project-specific parsing of args string (coming from setUri OSC message string)
	if ( argsList.size >= 2,
		{
			//~sheefaVec = argvec;

			postf(" particuleAlloc1.setup: node: %    args:   %    size:  %\n", nodeName, argsList, argsList.size);
			if ( argsList[0].asString == "voiceCount",
				{
					self.voiceCount = argsList[1].asInt.clip(1, 1000);   // clip to 1000 to avoid meltdown caused by error
					postf(" particuleAlloc1.setup: node: %   allocating %  voices \n", nodeName, self.voiceCount);
				},
				// else bad arg
				{
					error("particuleAlloc1.setup: unrecognized key, expecting 'voiceCount' ");
			});
	});

	if ( argsList.size >= 4,
		{
			//~sheefaVec = argvec;

			if ( argsList[2].asString == "synthName",
				{
					self.synthName = argsList[3].asString ;
					postf(" particuleAlloc1.setup: node: %   setting synth to %  \n", nodeName, self.synthName);
				},
				// else bad arg
				{
					error("particuleAlloc1.setup: unrecognized key, expecting 'synthName' ");
			});
	});


	self.voicePool = self.voiceCount;

	self.voiceVector =  Array.new(self.voicePool);
	self.voiceVector.postln;

	// now generate   self.voiceCount  synths in advance
	//  when the state problem is fixed, this can be done in the context of trigger, and synths can destroy  themselves after sounding
	self.voicePool.do( { arg item;
		var nodename=(self.nodeName++"_"++item).asSymbol;
		var synth;

		synth = ~scbr.makeInstance(nodename.asSymbol, self.synthName.asSymbol, self.nodeGroupName);
		self.voiceVector.add(synth);
		synth.set(\gainDB, -99);  // instantiate full attenuated
		synth.run(false);
	});
	postf("~particuleAlloc1.setup:  generating % synthVoice voices for group %\n",  self.voicePool, self.nodeGroupName);

	~particuleAlloc1_instances.put(self.nodeName.asSymbol, self);
};


// end of required class functions


// the functions below are not requied
// however if defined, they will be called by satie4unity


// if defined, will be called when node's "prop" message is received
// otherwise satie4unity will send the  "prop" message to the node's group
// ---- not used, since this class pre-allocates the voices... just use the group update
// ~particuleAlloc1.prop =  {| self, property, value |
// 	self.put(property.asSymbol, value);
// };



// if defined, will be called when node's "update" message is received
// otherwise satie4unity will send the  "update" message to the node's group
~particuleAlloc1.updateConnection = { | self, aziDeg, eleDeg, gainDB, delayMs, lpHz, distance |

	// do nothing for this node, since spatialization is done using the trigger method
};


// if defined, will be called when node's "spread" message is received
// otherwise the "spread" message will be applided to the node's group
~particuleAlloc1.spread = { | self, spreadVal |

	// do nothing for this node, since spatialization is only done using the trigger method

};


// totally custom functions.  Calls to these functions result from OSC events received by satie4unity from Unity, and then applied to these functions,  if they exist

~particuleAlloc1.setIncrement = { arg self, items = #[1] ;

	if ( items.size != 1,
		{
			warn("~particuleAlloc1.setIncrement:  bad item count,  takes one float arg, received: % items\n",items.size);
		},
		//else
		{
			postf("particuleAlloc1.setIncrement:  increment = % \n", items[0].asFloat);

			if (self.pitchSeqGlobalMode != 0,
				{
					~particuleAlloc1_pitchSequences.at(self.pitchSeqSym).put(\incr, items[0].asFloat);
				},
				// else
				{
					self.pitchSeqIncr = items[0].asFloat;
			});
	});
};


// custom method
// called with args:  // list: force, impactIncidence, aziDeg, eleDeg, gainDB, delayMs, lpHz, hpHz , distance
~particuleAlloc1.trigger = { arg self, items = #[1,2,3,4,5,6,7,8,9] ;
	var thisGroup = self.nodeGroup;
	var seqName, pitch, position, incr, size, vel, incidence;
	var aziDeg, eleDeg, gainDB, delayMs, lpHz, hpHz, distance;
	var xzDist, yDist, aziScaler, elevScaler;
	var synth;




	if ( items.size != 9,
		{
			postf("~particuleAlloc1.trigger:  bad item count, expecing '[ pitch vel incidence]' , received: % items\n",items.size);
		},
		{ // else

			// kind of stupid ti assert thus value t wat
			thisGroup.set(\randTrigMaxMs, self.triggerIntervalMs);

			// items.postln;

			seqName = self.pitchSeqSym;
			vel =  items[0].asFloat;
			incidence = items[1].asFloat.abs;   // not using negative values
			aziDeg = items[2].asFloat.raddeg;
			eleDeg = items[3].asFloat.raddeg;
			gainDB = items[4].asFloat;
			delayMs = items[5].asFloat;
			lpHz = items[6].asFloat;
			hpHz = items[7].asFloat;
			distance = items[8].asFloat;

			xzDist = distance * eleDeg.degrad.cos;  // get (horizontal) distance of node to listener on XZ plane
			yDist = distance * eleDeg.degrad.sin;  // get (vertical) distance of node to listener projected on Y axis

			xzDist = xzDist.clip(0, 100)*0.01;   // anything over 100 meters away will generate no azimuth offset its voices. Normalize

			yDist = yDist.clip(0, 100)*0.01;   // anything over 100 meters away will generate no azimuth offset its voices. Normalize

			aziScaler = (1 - xzDist)**self.cloudExp;   // increase this exponent to fall off more quickly
			elevScaler = (1 - yDist)**self.cloudExp;   // increase this exponent to fall off more quickly

			//[incidence, vel].postln;

			synth = self.voiceVector[self.voicePtr];
			self.voicePtr = (self.voicePtr + 1).mod(self.voicePool);

			size = ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\size);

			if (self.pitchSeqGlobalMode != 0,
				{

					position = ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\pos);
					incr = ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\incr);
					pitch = self.transposition + ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\pitches)[position];
					~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\pos,  ((position + incr) % size) );
				},
				// else   instance specific read
				{
					position = self.pitchSeqPos;
					incr = self.pitchSeqIncr;
					pitch = self.transposition + ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\pitches)[position];
					self.pitchSeqPos = ((position + incr) % size);
			});
					synth.run(true);

			synth.set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB,\delayMs, delayMs, \lpHz , lpHz, \hpHz, hpHz, \cloudAziScale,  aziScaler, \cloudElevScale, elevScaler, \pitch,  pitch, \force, vel, \incidence, incidence );
			synth.set(\t_trig, 1);
	});
};

// custom method
~particuleAlloc1.readPitches = { arg self, items = #["/tmp"] ;

	var pitchList, seqName, file, csvmidifilePath;

	//postf("readPitches:   arg 0: % \n",  items[0] );

	if ( items.size != 1,
		{
			warn("~particuleAlloc1.readPitches:  bad item count, expecting one filePath arg, received: % items\n",items.size);
		},
		//else
		{
			csvmidifilePath = items[0].asString;

			if (csvmidifilePath[0] != $/,
				{
					csvmidifilePath = ~satie4unity.projectDirectory++"/"++csvmidifilePath;
			});

			csvmidifilePath.postln;

			pitchList = List.new();
			seqName = csvmidifilePath.split.last;
			file = File(csvmidifilePath.standardizePath,"rb");

			// process only if pitch sequence has not yet been loaded
			if ( ~particuleAlloc1_pitchSequences.includesKey(seqName.asSymbol),
				{

					//  file already loaded, just set instance  specific state
					postf("particuleAlloc1.readPitches:  sequence % already loaded, skipping file load\n", seqName);
					self.pitchSeqSym = seqName.asSymbol;
					self.pitchSeqLen = ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).at(\size);
					// self.pitchSeqPos = 0;    DONT RESET READ HEAD

					// and reset sequence's global state  BUT DO NOT RESET READ HEAD
					// ~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\pos, 0);
					~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\incr, self.pitchSeqIncr);   // using instance specific state.. may overwrite


				},
				// else  read file and create pitch sequence
				{
					//postf("file % length:  %\n", csvmidifilePath, file.length);

					file.do({
						var value, event;

						value = file.getLine();

						if (value.contains("Note_on_c"),
							{
								event = value.split($,);
								pitchList.add(event[4].asInt);
						});
					});

					file.close;

					if (pitchList.size > 0,
						{
							postf("% pitches read from file %\n", pitchList.size,  csvmidifilePath);
							// add sequence to dictionary

							~particuleAlloc1_pitchSequences.removeAt(seqName.asSymbol);   // overwrite previous

							~particuleAlloc1_pitchSequences.put(seqName.asSymbol, Dictionary.new());
							~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\pitches, pitchList);
							~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\size, pitchList.size);
							~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\pos, 0);
							~particuleAlloc1_pitchSequences.at(seqName.asSymbol).put(\incr, 1);


							//~particuleAlloc1_pitchSequences.removeAt(seqName.asSymbol);
							//~particuleAlloc1_pitchSequences.put(seqName.asSymbol, pitchList);
							//~particuleAlloc1_pitchSequences.put(seqName.asSymbol,

							// set instance local state -- currently not used, but available for future deployment
							self.pitchSeqSym = seqName.asSymbol;
							self.pitchSeqLen = pitchList.size;
							self.pitchSeqPos = 0;
						},
						//else
						{
							warn("no pitches found in file: "++csvmidifilePath);
					});
			});
	});
};

/*
testing

~myFile =  "/Users/zack/Dropbox/Unity3D/projects_unity5/balljamDemoSATIE_2015_unity5/Assets/StreamingAssets/midi/pitchSequences/bjGroove.mid.mid.txt";
~particuleAlloc1.readPitches(~myFile);
~particuleAlloc1.pitchSeqLen;
~particuleAlloc1.pitchSeqName;

*/
