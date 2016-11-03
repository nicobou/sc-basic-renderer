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

//  s.makeGui;
// s.reboot;


(
/*

s.quit;

Server.default;

Server.supernova;

s.boot;
s.reboot;

~allNodes.size;
*/




~synthdefCreationLatency = 0.5;    // the time interval between the creation of a synthdef (plugin) and the opening of its connection RX gate



// set these flags depending on your environment

~superNovaFlag = true;

//~domePlayback = true;
// ~labodome = true;
//~outAudioDev = "Soundflower (64ch)";   //  for multi-channel testing without hardware on OSX
//  ~outAudioDev = "MADIface USB (23635751)"     // for labodome or SATO


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


if ( ~labodome != nil,
	{
		o.numOutputBusChannels = 24;
		o.memSize = 2**19;
		o.blockSize = 2048;
		// o.dump;
});

if ( ~domePlayback != nil,
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

	if ( ~domePlayback == nil,
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
			~scbr.makeSynthDef(\labodomeTest, \default, [\labodomeVBAP], [0]);
	},
		// else evalualte for dome listeners
		{
			'generating synthdefs for dome'.postln;
			~scbr.makeSynthDef(\pink, \PinkSin, [\domeVBAP], [0]);
			~scbr.makeSynthDef(\dust, \DustDust, [\domeVBAP], [0]);
			~scbr.makeSynthDef(\default, \default, [\domeVBAP], [0]);
			~scbr.makeSynthDef(\zkarpluck0, \zkarpluck0, [\domeVBAP], [0]);
			~scbr.makeSynthDef(\zkarpluck1, \zkarpluck1, [\domeVBAP], [0]);
			~scbr.makeSynthDef(\zbell1, \zbell1, [\domeVBAP], [0]);
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
		var nodeName, listenerName, connectionName, type, temp, charIndex;
		var aziDeg, eleDeg, gainDB, delayMs, lpHz, spread;
		var proxy;

		//args.postln;
		connectionName = args[0].asString.split[4].asSymbol;   // this is terrible.  ThespatOSC message format could be improved here
		type = args[0].asString.split[5].asSymbol;
		charIndex = connectionName.asString.find("->");

		nodeName = connectionName.asString.subStr(0, charIndex-1);

		//postf("~connectionCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);

		proxy = ~allNodes[nodeName.asSymbol].at(\proxy);

		switch(type,
			'update',
			{
				if ( (args.size != 6 ) ,
					{"connectionCallback: OSCrx update message missing values".warn;},
					// else
					{
						// get values from vector, and write to connectionState
						aziDeg = args[1].raddeg;
						eleDeg= args[2].raddeg;
						gainDB = args[3];
						delayMs = args[4];
						lpHz = args[5];

						proxy[\out].set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz);
					}
				)
			},
			'spread',
			{
				if ( (args.size > 0 ) ,
					{
						//postf("~connectionCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);
						spread = args[1];  // get values from vector, and write to connectionState
						//args.postln;
						proxy[\out].set(\spread, spread);

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

	~globalParGroup = ParGroup.new;  // for now, we use just one global parGroup, for reasons of efficiency

	// define some functions to handle actions
	~createSource = { | sourceName |
		var proxy;
		if (~allNodes.includesKey(sourceName),
			{
				postf("~createSource:   % exists, no action\n", sourceName);
			},
			// else create new node
			{
				postf("~createSource:   %\n", sourceName);
				~allNodes[sourceName.asSymbol] = Dictionary();   // create node  -- create node-specific dict.

				~allNodes[sourceName.asSymbol].put(\groupName, ~globalParGroup);  // create node-specific group and add to node dict.
				proxy = ProxySpace(s);
				proxy.fadeTime = 0.02;
				proxy[\out].ar(0);  //    this prevents an extra bus being allocated. this must be the first reference of ~out

				//proxy[\out].group = ~globalParGroup;     // enabling this causes all members of the group to update each other.

				~allNodes[sourceName.asSymbol].put(\pluginName, \nil);
				~allNodes[sourceName.asSymbol].put(\proxy, proxy);

				~scbr.oscInterface.sourceOSC(sourceName.asSymbol, ~sourceCallback);   // create OSC callback for this source

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
			// else create new one,  and a corresponding OSC callback
			{
				~allNodes[sourceName.asSymbol].put(\connectionName, connectionName.asSymbol);

				~scbr.oscInterface.connectionOSC(~allNodes[sourceName.asSymbol].at(\connectionName),~connectionCallback );

				// postf("~createConnection: creating callback for  %  ", ~allNodes[sourceName.asSymbol].at(\connectionName));
		});
	};


	// update a node's plugin (synthdef)
	~setPlugin = { | nodeName pluginName |
		var thisProxy = ~allNodes[nodeName.asSymbol].at(\proxy);

		// if overwriting a synthdef, this assignment will automatically kill off the previous one; all the proxy's current synthdef state will be copied to the new one
		thisProxy[\out].source = pluginName.asSymbol;
		};


	// value is a uri path:   file://~/Desktop/sheefa8.aif, plugin://testnoise~ , adc://1
	~setUri = { | name, value |
		var charIndex, uriPath, type, temp;

		// type://name (i.e. plugin://DustDust, file://<path>

		charIndex = value.asString.find("://");

		temp = value.asString.subStr(charIndex);
		type = value.asString.subStr(0, charIndex-1);
		uriPath = temp.asString.replace("://", "");

		//postf("~setUri nodeName: %, type: %  plugName: %\n", name, type, uriPath);
		// still needs to be expanded for soundfiles, adc, web etc..
		switch( type,
			"plugin", {
					~setPlugin.value(name.asSymbol, uriPath)

			},
			// "file", {~setPlugin.value(name, uriPath)}  not implemented yet
		);
	};


	// always a keyWord Value pair
	~setProperty = { | nodeName property value |
		var thisProxy = ~allNodes[nodeName.asSymbol].at(\proxy);

		//postf("~setProperty: seting % of % to %\n", property, nodeName, value);
		thisProxy[\out].set(property.asSymbol, value);   // set Prop  -- update synthDef plugin
	};


	// enable/disable node
	~setState = { | nodeName,  state |
		var thisProxy = ~allNodes[nodeName.asSymbol].at(\proxy);
		if ( (state > 0),
			{thisProxy[\out].resume},
			{thisProxy[\out].pause}
		);
		//postf("~setState: seting state of % to %\n", nodeName, state);
	};

	// events RX:   /spatosc/core/source/nodename/event eventName v1...vN
	~setEvent = { | nodeName, eventName,  args |
		var valueCount = args.size-1;
		var thisProxy = ~allNodes[nodeName.asSymbol].at(\proxy);

		//postln("~setEvent: node:" ++nodeName ++" event name:"++eventName++"  arg(s): "++ args );

		if ( (valueCount >= 1) ,    // pass vector
			{
				thisProxy[\out].set(eventName, args);
			},
			// else
			{
				if ( (valueCount == 1) ,    // pass value
					{
						thisProxy[\out].set(eventName, args[0]);
					},
					// else  no args.. just pass 1
					{
						thisProxy[\out].set(eventName, 1);  // no args, just add one to generate trigger event
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
		var thisProxy = node.at(\proxy);

		// 'deleting synth'.postln;
		//postf("~deleting:  node: % and connection: %\n",  nodeName, connectionName);

		// disconnect callbacks
		~scbr.oscInterface.removeConnectionOSC(connectionName.asSymbol);
		~scbr.oscInterface.removeSourceOSC(nameSym);

		thisProxy.release(0.1);  // free this node's synthdef (plugin)

		//  clear node's local dictionary
		// maybe this is unnecessary
		nodeKeys.do { | key |
			node.removeAt(key);
		};
	};


	~globalSetState = { | state |
		'Setting Global state'.postln;
		~allNodes.keysDo { |key |
			//key.postln;
			~setState.value(key, state);
		};
	};

	~globalSet = { | param, value |
		var thisProxy;
		~allNodes.keysDo { |key |
			//key.postln;
			thisProxy = ~allNodes[key].at(\proxy);
			thisProxy[\out].set(param,value);
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



	~deleteSource.value(\testNode8);

	~dumpNodes.value();

	~allNodes.size;

	~clearScene.value();


// generate N instances

	1.do({ arg item;
	var nodename=("testNode"++item).asSymbol;
	var connectionName = "testNode"++item++"->ear";

	~createSource.value(nodename);
	//~createConnection.value(nodename, "ear");
	~setUri.value(nodename, "plugin://default");
	//~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName ++"/spread", 10]);
		       });


	~createSource.value(\testNode0);

	p = ~allNodes[\testNode0].at(\proxy);

	p[\outDB] = -3;

	p[\out].source = \fool;
		~globalParGroup.set(\gainDB, -0);

		~globalParGroup.freeAll;




	~setUri.value(\testNode0, "plugin://default");



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

