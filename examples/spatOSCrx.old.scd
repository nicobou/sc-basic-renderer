//// This program is free software: you can redistribute it and/or modify
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

/* debugging
 OSCFunc.trace(true);
 OSCFunc.trace(false);
*/

/*
NOTES:
this implementation is based on a one-listener model. In the future, we may wish to exapnd this to integrate more than one.  In such a case, proivision will have to be made so that multiple listener synth-defs can be defined.
OSC RX message specification is based on the SPATOSC specification  (see:   http://code.sat.qc.ca/redmine/projects/spatosc/wiki/spec  )
*/

/*

s.makeGui;
s.meter

 s.reboot;
*/

(
/*

s.quit;

Server.default;

Server.supernova;

s.boot;
s.reboot;

~allNodes.size;
*/




~synthdefCreationLatency = 1.0;    // the time interval between the creation of a synthdef (plugin) and the opening of its connection RX gate

~globalParGroup = ParGroup.new;  // for now, we use just one global parGroup, for reasons of efficiency


// set these flags depending on your environment

~superNovaFlag = true;

//~domePlaybackFormat = \domeVBAP;       // for sato
~domePlaybackFormat = \labodomeVBAP;      // for labodome


//~outAudioDev = "Soundflower (64ch)";   //  for multi-channel testing without hardware on OSX

~outAudioDev = "MADIface USB (23635751)";     // for labodome or SATO


if ( ~superNovaFlag != nil,
	{
	Server.supernova;
});

	o = Server.local.options;   // set up options
    o.memSize = 2**19;        // probably should just leave this the same for everyting
	//o.blockSize = 2048;


if ( ~outAudioDev != nil ,
{
	o.device = ~outAudioDev;
});

   // o.device = "MADIface USB (23635751)";     // set for dome or labodome

if ( ~domePlaybackFormat != nil,
	{
		o.memSize = 2**19;
		o.blockSize = 2048;
		o.numOutputBusChannels = 32;
		// o.dump;
});

// Server.default.options.dump;


s.waitForBoot{

	// finding source directory
	~rootSrcPath = thisProcess.nowExecutingPath.dirname ++ "/..";
	(~rootSrcPath ++ "/src/*.scd").pathMatch.do({arg item; item.loadPaths});

	// creating a sc-basic-renderer
	~scbr = ~scbrMaker.value(~rootSrcPath);

	// loading source plugins
	~scbr.pluginLoader.loadAudioPlugins(~rootSrcPath ++ "/audiosources/*.scd");

	// see the loaded plugins in the console
	~scbr.pluginLoader.audioPlugins.postln;

	// loading spatializer plugins
	~scbr.pluginLoader.loadSpatPlugins(~rootSrcPath ++ "/spatializers/*.scd");
	~scbr.pluginLoader.spatPlugins;

	~scbr.makeSynthDef(\dummyPlugin, \emptySource, [\emptySpat], [0]);    // dummy synthdef, used for new nodes

	if ( ~domePlaybackFormat == nil,
		{
			// NEEDS IMPROVEMENT
			// all plugins (synthDefs) have to be evaluated in "pre-runtime" herea
			//
			'generating synthdefs'.postln;

			~scbr.makeSynthDef(\pink, \PinkSin, [\stereoPanner, \monoSpat], [0, 2]);
			~scbr.makeSynthDef(\dust, \DustDust, [\stereoPanner, \monoSpat], [0, 2]);
			~scbr.makeSynthDef(\default, \default, [\stereoListener], [0]);
			~scbr.makeSynthDef(\zkarpluck0, \zkarpluck0, [\stereoListener], [0]);
			~scbr.makeSynthDef(\zkarpluck1, \zkarpluck1, [\stereoListener], [0]);
			~scbr.makeSynthDef(\zbell1, \zbell1, [\stereoListener], [0]);
			~scbr.makeSynthDef(\test, \testtone, [\stereoListener], [0]);
			~scbr.makeSynthDef(\labodomeTest, \default, [\labodomeVBAP], [0]);
	},
		// else evalualte for dome listeners
		{
			postf("generating synthdefs for %\n", ~domePlaybackFormat);
			~scbr.makeSynthDef(\pink, \PinkSin, [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\dust, \DustDust, [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\default, \default, [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\zkarpluck0, \zkarpluck0, [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\zkarpluck1, \zkarpluck1, [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\test, \testtone,  [~domePlaybackFormat], [0]);
			~scbr.makeSynthDef(\zbell1, \zbell1, [~domePlaybackFormat], [0]);
		}
	);

	// be sure the synthDefs are compiled on the server
	s.sync;

	OSCdef(\createSoundSource).clear.free;  // just in case newOSC will be re-evaluated.
	~scbr.oscInterface.newOSC(\createSoundSource, ~coreCallback, "/spatosc/core");


	// dictionarys for nodes
	~allNodes = Dictionary();        //  ~allNodes.postln;
	//~allConnections = Dictionary();   // separate for faster access  // ~allConnections.postln;


	~coreCallback = {
		arg msg;
		var command;
		command = msg[1];
		//postf("~coreCallback: command: %, msg: %, \n", command, msg);

		switch (command,
			'createSource',
			{
				if ( (msg.size < 3 ) ,
					{"~coreCallback: OSCrx createSource message missing values".warn;},
					// else
					{
						var sourceName = msg[2];
						~createSource.value(sourceName);
					}
				)
			},
			'createSoundSource',   // this will be dropped as soon as spatOSC is updated to use the "createSource" message instead
			{
				if ( (msg.size < 3 ) ,
					{"~coreCallback: OSCrx createSource message missing values".warn;},
					// else
					{
						var sourceName = msg[2];
						~createSource.value(sourceName);
					}
				)
			},
			'deleteNode',
			{
				if ( (msg.size < 3 ) ,
					{"~coreCallback: OSCrx deleteNode message missing values".warn;},
					// else
					{
						var sourceName = msg[2];
						~deleteSource.value(sourceName);
					}
				)
			},
			'clear', {~clearScene.value();},
			'connect',
			{
				if ( (msg.size < 4 ) ,
					{"~coreCallback: OSCrx connect message missing values".warn;},
					// else
					{
						var sourceName, listenerName;
						sourceName = msg[2];
						listenerName = msg[3];
						~createConnection.value(sourceName, listenerName);
					}
				)
			};
		);
	};


	// ~connectionCallback = { | args |       // for debugging
	// 	~processConnection.value( args );
	// };


	// /spatosc/core/connection/source->listener/update azi elev delayMS gainDB lpHZ
	// /spatosc/core/connection/source->listener/spread  exp   // exponent for incidence effect
	~connectionCallback = { | args |
		var nodeName, listenerName, connectionName, type, values, temp, charIndex;
		var aziDeg, eleDeg, gainDB, delayMs, lpHz, spread;
		var connectionState;
		var thisNode;

		//args.postln;
		connectionName = args[0].asString.split[4].asSymbol;   // this is terrible.  ThespatOSC message format could be improved here
		type = args[0].asString.split[5].asSymbol;
		charIndex = connectionName.asString.find("->");

		nodeName = connectionName.asString.subStr(0, charIndex-1);

		//postf("~connectionCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);

		thisNode = ~allNodes[nodeName.asSymbol];
		connectionState = thisNode.at(\connectionState);  // writing to this will write to the node's dictionary

		switch(type,
			'update',
			{
				if ( (args.size != 6 ) ,
					{"connectionCallback: OSCrx update message missing values".warn;},
					// else
					{
						values = args;
						//values.removeAt(0);

						eleDeg= values[2].raddeg;
						if (eleDeg == 0, { eleDeg = 0.06});    // TREEIBLE KLUGE TO KEEP VBAP FROM EXPLODING

						// get values from vector, and write to connectionState
						connectionState[0] = aziDeg = values[1].raddeg;
						connectionState[1] = eleDeg;
						connectionState[2] = gainDB = values[3];
						connectionState[3] = delayMs = values[4];
						connectionState[4] = lpHz = values[5];

						// update plugin synthDef state   (servrer)
						if (  thisNode.at(\pluginReady),
							{
								thisNode.at( \pluginNode ).set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz);
						});
					}
				)
			},
			'spread',
			{
				if ( (args.size > 0 ) ,
					{
						//postf("~connectionCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);
						connectionState[5] = spread = args[1];  // get values from vector, and write to connectionState
						//args.postln;
						if (  thisNode.at(\pluginReady),
							{
							thisNode.at( \pluginNode ).set( \spread, spread );   // update plugin synthDef state
						});
					},
					// else
					{"~connectionCallback: OSCrx spread message with no values".warn; })
			};
		);
	};


	// e.g  /spatosc/core/source/nodename/prop  key val
	~sourceCallback = {
		| args |
		var name, type, values, eventName, state;
		name = args[0].asString.split[4].asSymbol;
		type = args[0].asString.split[5].asSymbol;

		//'~sourceCallback'.postln;

		switch(type,
			'prop', {~setProperty.value(name, args[1], args[2])},
			'uri', {~setUri.value(name, args[1])},
			'event',
			{
				//postf("~sourceCallback:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args);
				if ( (args.size < 2 ) ,
					{"~setEvent: OSCrx message with no values".warn;},
					{  // else
						values = args;
						eventName = args[1];
						values.removeAt(0);
						values.removeAt(0);
						~setEvent.value(name, eventName, values);
					}
				)
			},
			'state',
			{
				if ( (args.size > 1) ,
					{
						state = args[2];
						eventName = args[1];
						~setState.value(name, eventName, args[2]);
					},
					{"~setState: OSCrx message with no values".warn; })  // else
			},
			{postf("~sourceCallback:  UNMATCHED:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args)};
		);
	};

	// define some functions to handle actions
	~createSource = { | sourceName |
		if (~allNodes.includesKey(sourceName),
			{
				postf("~createSource:   % exists, no action\n", sourceName);
			},
			// else create new node
			{
				postf("~createSource:   %\n", sourceName);
				~allNodes[sourceName.asSymbol] = Dictionary();   // create node  -- create node-specific dict.

				~allNodes[sourceName.asSymbol].put(\groupName, ~globalParGroup);  // add to prexisting parGroup

				~allNodes[sourceName.asSymbol].put(\pluginName, \dummyPlugin);
				~allNodes[sourceName.asSymbol].put(\pluginReady, false);  // this flag is used to keep messages from being prematurely sent to synthdefs (not yet instantiated on server)

				// create client-side state register for connection values
				~allNodes[sourceName.asSymbol].put(\connectionState,  Array.with(0,0,0,1,15000,1)); // aziDeg = 0, eleDeg = 0, gainDB = 0, delayMs = 1, lpHz = 15000, spread = 1

				//  instantiate an empty synthdef for new node, so that its listener state is defined and can be updated

				~allNodes[sourceName.asSymbol].put(\pluginNode, Synth(~allNodes[sourceName.asSymbol].at(\pluginName),nil,~allNodes[sourceName.asSymbol].at(\groupName),\addToHead));

				~scbr.oscInterface.sourceOSC(sourceName.asSymbol, ~sourceCallback);

				//'adding synth'.postln;
			}
		);
		//~allNodes.postln;
	};

	~createConnection = { |sourceName listenerName |
		var connectionName = sourceName ++ "->" ++ listenerName;

		if (  ~allNodes.includesKey(sourceName.asSymbol) == false ,
			// source not defined  ???
			{
				postf("warning: ~createConnection: SOURCE % not defined \n", sourceName);
		});

		if ( ~allNodes[sourceName.asSymbol].includesKey(\connectionName),
			{
				'~createConnection:  connection already exists, no action taken'.postln;
			},
			// else create new one
			{
				~allNodes[sourceName.asSymbol].put(\connectionName, connectionName.asSymbol);

				~scbr.oscInterface.connectionOSC(~allNodes[sourceName.asSymbol].at(\connectionName),~connectionCallback );

				// postf("~createConnection: creating callback for  %  ", ~allNodes[sourceName.asSymbol].at(\connectionName));
		});
	};

	~pluginStatus = { | nodeName, status |
		//postf("~pluginStatus: setting % stats to % \n", nodeName, status);
		~allNodes[nodeName.asSymbol].put(\pluginReady, status);

		if (  ~allNodes[nodeName.asSymbol].at(\pluginReady),   // refresh connection values in synthdef  ??
			{
				~refreshConnection.value(nodeName);
		});
	};


	// sends current connection state to synthdef (plugin)
	~refreshConnection = { | nodeName |
		var connectionState = ~allNodes[nodeName.asSymbol].at(\connectionState);
		var aziDeg = connectionState[0];  // aziDeg = 0, eleDeg = 0, gainDB = 0, delayMs = 1, lpHz = 15000, spread = 1
		var eleDeg = connectionState[1];
		var gainDB = connectionState[2];
		var delayMs = connectionState[3];
		var lpHz = connectionState[4];
		var spread = connectionState[5];

		// set connectionvalues in synthdef (plugin)  to current state
			~allNodes[nodeName.asSymbol].at( \pluginNode ).set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz, \spread, spread );
	};


	// update a node's plugin (synthdef)
	~setPlugin = { | nodeName pluginName |
		var nodeNameSym = nodeName.asSymbol;
		var pluginNameSym = pluginName.asSymbol;
		var thisNode = ~allNodes[nodeNameSym];
		var connectionState = thisNode.at(\connectionState);

		// get current connectionState
		var aziDeg = connectionState[0];  // aziDeg = 0, eleDeg = 0, gainDB = 0, delayMs = 1, lpHz = 15000, spread = 1
		var eleDeg = connectionState[1];
		var gainDB = connectionState[2];
		var delayMs = connectionState[3];
		var lpHz = connectionState[4];
		var spread = connectionState[5];

		// the following is a KLUGE to prevent corruption of the server's synthdef state by "premature" message reception   (this should be understood and FIXED !)
		// temporarly disable connection updates to synthdef (plugin) on server, and then schedule re-enabling of same
		~pluginStatus.value(nodeNameSym, false);

		SystemClock.sched(~synthdefCreationLatency,{
			~pluginStatus.value(nodeNameSym, true);
			    nil;
		});

		thisNode.put(\pluginName, pluginNameSym);   // set URI:
		// postf("~setPlugin: : %,  node: %, \n", pluginName, nodeName);
		// thisNode.at(\groupName).freeAll;   // DO NOT DO PER NODE  clear current synthNode(s) in group

		thisNode.at(\pluginNode).free;     // kill off existing synthdef (plugin)

		// create fresh synthDef plugin.
		thisNode.put(\pluginNode, Synth(~allNodes[nodeNameSym].at(\pluginName),nil,~allNodes[nodeNameSym].at(\groupName),\addToHead));

		// set connection to current state
		thisNode.at( \pluginNode ).set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz, \spread, spread );
	};


	// value is a uri path:   file://~/Desktop/sheefa8.aif, plugin://testnoise~ , adc://1
	~setUri = { | name, value |
		var charIndex, uriPath, type, temp;

		// type://name (i.e. plugin://DustDust, file://<path>

		charIndex = value.asString.find("://");

		temp = value.asString.subStr(charIndex);
		type = value.asString.subStr(0, charIndex-1);
		uriPath = temp.asString.replace("://", "");

		// postf("~setUri nodeName: %, type: %  value: %\n", name, type, uriPath);


		// still needs to be expanded for soundfiles, adc, web etc..
		switch( type,
			"plugin", {
					~setPlugin.value(name, uriPath)

			},
			// "file", {~setPlugin.value(name, uriPath)}  not implemented yet
		);
	};


	// always a keyWord Value pair
	~setProperty = { | nodeName property value |
		//postf("~setProperty: seting % of % to %\n", property, nodeName, value);

		~allNodes[nodeName.asSymbol].at( \pluginNode ).set(property.asSymbol, value);   // set Prop  -- update synthDef plugin
	};


	// enable/disable node
	~setState = { | nodeName,  state |
		if ( (state > 0),
			{state = 1},
			{state = 0}
		);
		//postf("~setState: seting state of % to %\n", nodeName, state);

		~allNodes[nodeName.asSymbol].at( \pluginNode ).run(state);

	};

	// events RX:   /spatosc/core/source/nodename/event eventName v1...vN
	~setEvent = { | nodeName, eventName,  args |
		var valueCount = args.size-1;

		//postln("~setEvent: node:" ++nodeName ++" event name:"++eventName++"  arg(s): "++ args );

		if ( (valueCount >= 1) ,    // pass vector
			{
				~allNodes[nodeName.asSymbol].at( \pluginNode ).set(eventName, args);
			},
			// else
			{
				if ( (valueCount == 1) ,    // pass value
					{
						~allNodes[nodeName.asSymbol].at( \pluginNode ).set(eventName, args[0]);
					},
					// else  no args.. just pass 1
					{
						~allNodes[nodeName.asSymbol].at( \pluginNode ).set(eventName, 1);  // no args, just generate trigger event
					}
				);
		});
	};


	~clearScene = {
		var nodelist = ~allNodes.keys;

		'CLEARING SCENE'.postln;

		// first flush all nodes
		~allNodes.keysDo { |key |
			~clearNode.value(key);
		};
		// now remove all nodes in the global dictionary
		nodelist.do { | key |
						postf("removing:  node: %  from dictionary\n",  key);
								~allNodes.removeAt(key);
					};

		~allNodes.size;
	};



	~deleteSource = { | nodeName |
		if ( ~allNodes.includesKey(nodeName.asSymbol) ,
			{  ~clearNode.value(nodeName.asSymbol);
					~allNodes.removeAt(nodeName.asSymbol);     // remove node from global dictionary
		});
	};

	~clearNode= { | nameSym |
		var node = ~allNodes[nameSym];
		var connectionName = node.at(\connectionName);
		var nodeKeys = node.keys;

		// 'deleting synth'.postln;
		//postf("~deleting:  node: % and connection: %\n",  nodeName, connectionName);

		// disconnect callbacks
		~scbr.oscInterface.removeConnectionOSC(connectionName.asSymbol);
		~scbr.oscInterface.removeSourceOSC(nameSym);

		// node.at(\groupName).free;   //  clear group and all active synthNodes

		node.at(\pluginNode).free;  // free this node's synthdef (plugin)

		//  clear node's local dictionary
		nodeKeys.do { | key |
			node.removeAt(key);
		};
	};


	~globalSetState = { | state |
		'Setting Global state'.postln;
		~allNodes.keysDo { |key |
			//key.postln;

			~allNodes[key].at( \pluginNode ).run(state);
		};
	};

		~globalSet = { | param, value |
		~allNodes.keysDo { |key |
			//key.postln;

			~allNodes[key].at( \pluginNode ).set(param,value);
		};
	};


		~dumpNodes = {
		~allNodes.keysDo { |key |
			var nodeSym = key;
			postf("node: %  \n", key);
			~allNodes[nodeSym].keysDo { | key |
					postf("\t : %  =  % \n",  key, ~allNodes[nodeSym].at(key));
			};
		};
	};


	s.sync;





	/*  TEMP

	~allNodes.size;
	~globalSetState.value(0);
	~globalSetState.value(1);

	~nodeName="sourceC:spatOSCsource_0".asSymbol;
	~nodeName="ball_0:spatOSCsource_1".asSymbol;



	~nodeName=\mySound;
	~listenerName=\ear;
	~connectionName= ~nodeName ++ "->" ++ ~listenerName;


	~createSource.value(~nodeName);

	~createConnection.value(~nodeName, "ear");

	~setUri.value(~nodeName, "plugin://default");

	~setUri.value(~nodeName, "plugin://zkarpluck1");


	~allNodes[~nodeName].release;

	~allNodes[~nodeName].at( \pluginNode ).set(\note, [60,1,0.5]);
		~allNodes[~nodeName].at( \pluginNode ).set(\t_trig, 1);


	~allNodes[~nodeName].at( \pluginNode ).set(\aziDeg, 180, \eleDeg, 20, \gainDB, -6, \delayMs, 2, \lpHz, 8000, \spread, 1 );


	~deleteSource.value(\testNode8);

	~dumpNodes.value();

	~allNodes.size;

	~clearScene.value();


// generate N instances

	80 .do({ arg item;
	var nodename=("testNode"++item).asSymbol;
	var connectionName = "testNode"++item++"->ear";

	~createSource.value(nodename);
	~createConnection.value(nodename, "ear");
	~setUri.value(nodename, "plugin://default");
	~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName ++"/spread", 10]);
		       });


	~globalSet.value(\fb, 100);

	~globalSet.value(\pos, 0);
	~globalSet.value(\pos, 0.5);
	~globalSet.value(\pos, 1);

	~globalSet.value(\gainDB, -30);
	~globalSet.value(\spread, 10);




w=Window.new("group contrp;", Rect(30, 30, 400, 100)).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=8@2;


h = EZSlider(w, 380@20, "azi", ControlSpec(-180, 180, \lin, 1, 0));
h.action_({ |ez| ( ~globalSet.value(\aziDeg, (ez.value)))});

i = EZSlider(w, 380@20, "ele", ControlSpec(-90, 90, \lin, 1, 0));
i.action_({ |ez| (~globalSet.value(\eleDeg, (ez.value)))});

j = EZSlider(w, 380@20, "spread", ControlSpec(0, 100, \lin, 0.1, 1));
j.action_({ |ez| ( ~globalSet.value(\spread, (ez.value)))});



	~allNodes[~nodeName].put(\connectionState,  Array.with(90,0,0,1,15000,100));   // create client-side state register for connection values
	~connectionState = ~allNodes[~nodeName].at(\connectionState);


	~allNodes[~nodeName].at(\connectionState)[4];


	~allNodes[~nodeName].at(\connectionState)[4];

	 // \aziDeg, 0, \eleDeg, 0, \gainDB, 0, \delayMs, 1, \lpHz, 15000, \spread, 1  // default connection values



	~setUri.value(~nodeName, "plugin://default");

	~setUri.value(~nodeName, "plugin://labodomeTest");

	~allNodes[~nodeName].at(\pluginName);

	~allNodes[~nodeName].at( \pluginNode ).run(1);

	~allNodes[~nodeName].at( \pluginNode ).set(\t_gate, 1);

	~allNodes[~nodeName].at( \pluginNode ).set(\outputDB, 18);


	~allNodes[~nodeName].at( \pluginNode ).set(\spread, 9);

	~allNodes[~nodeName].at( \pluginNode ).get(\spread, { arg value; ("spread is now:" + value ).postln });


	~spread.postln;

	~allNodes[~nodeName].at( \pluginNode ).dump;

	~allNodes[~nodeName].at(\groupName).dump;

	~allNodes[~nodeName].at( \pluginNode )

	~allNodes[~nodeName].includesKey( \pluginNode )


	~allNodes[~nodeName].at( \pluginNode ).set(\gainDB, 0);

	~sourceCallback.value( ["/spatosc/core/source/"++ ~nodeName ++"/event", \note, 50, 0.01,1]);
	~sourceCallback.value( ["/spatosc/core/source/"++ ~nodeName ++"/event", \t_trig, 1]);

	~allNodes[~nodeName].at( \pluginNode ).set(\note, [60,0.2,0]);
		~allNodes[~nodeName].at( \pluginNode ).set(\t_trig, 1);


~connectionCallback.value( ["/spatosc/core/connection/"++ ~connectionName ++"/spread", 5]);


	~deleteSynth.value(~nodeName);
	~clearScene.value();





	*/
};
)

