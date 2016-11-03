// Satie4Unity, audio rendering support for Unity
// Copyright (C) 2016  Zack Settel
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
/*
NOTES:
this implementation is based on a one-listener model. In the future, we may wish to exapnd this to integrate more than one.  In such a case, proivision will have to be made so that multiple listener synth-defs can be defined.
Satie4Unity's message specification is inspired from the SPATOSC specification  (see:   http://code.sat.qc.ca/redmine/projects/spatosc/wiki/spec  )
*/

/*
for debugguing

~satie4unity = ~satie4unityprotocol.value(~oscInterface, ~scbr);
~satie4unity.debugFlag = true;
~satie4unity = ~satie4unityprotocol.value(~oscInterface, ~scbr);

*/


(
~satie4unityprotocol = { | oscContext, satieContext, oscID = \satie4unityOSC |
	var osc = oscContext;
	var satie = satieContext;

	var e = Environment.make({
		~allSourceNodes = Dictionary();        //  ~allSourceNodes.postln;
		~allGroupNodes = Dictionary();        //  ~allGroups.postln;
		~projectDirectory = nil;

		// used for audio renderer control
		~volume = s.volume;     // create hook to global audio engine volume / mute control
		~volume.setVolumeRange(-99, 18);
		~outputDB = 0;    // current state of the supercollider's output
		~outputTrimDB = 0;
		~debugFlag=false;

		~satieAuxBusCount = satie.aux.size;

		// make sure this effcts group is defined since all  uri types "effect://name" are assigned to it
		if ( satie.satieGroups[\effect] == nil,
			{~effectProx = satie.makeSatieGroup(\effect, \addToTail);}
		);

		~allProcesses = ();    // initialize list for processes to register themselves;

		// ~basicRendererCallback = { "basicRendererCallback called".inform };
		~basicRendererCallback = {
			arg msg;
			var command = msg[1];
			//postf("~basicRendererCallback: command: %, msg: %, \n", command, msg);

			if (msg.size < 2,
				{"~basicRendererCallback: empty message".warn;
					postf("~basicRendererCallback MESS LEN: %", msg.size);

				},
				// else
				{

					switch (command,
						'setProjectDir',
						{
							if ( (msg.size != 3 ) ,
								{"~basicRendererCallback: setProjectDir bad arg count: expecting 'setProjectDir projectDirPath' ".warn;},
								// else
								{
									e.projectDirectory = msg[2];

									//e.projectDirectory.postln;
									postf("~basicRendererCallback: setProjectDir: % \n", e.projectDirectory);

								}
							)
						},
						'setOutputTrimDB',
						{
							if ( (msg.size < 3 ) ,
								{"~basicRendererCallback: setOutputTrimDB missing value".warn;},
								// else
								{
									e.outputTrimDB = msg[2];
									e.volume.volume = e.outputTrimDB + e.outputDB;
								}
							)
						},
						'setOutputDB',
						{
							if ( (msg.size < 3 ) ,
								{"~basicRendererCallback: setOutputDB missing value".warn;},
								// else
								{
									e.outputDB = msg[2];
									e.volume.volume = e.outputTrimDB + e.outputDB;
								}
							)
						},
						'setOutputDIM',
						{
							if ( (msg.size < 3 ) ,
								{"~basicRendererCallback: setOutputMute missing value".warn;
									// postf("CREATESOURCE MESS LEN: %", msg.size);

								},
								// else
								{
									if (msg [2] > 0,
										{  e.volume.volume = -30;  },
										// else
										{  e.volume.volume =  e.outputDB + e.outputTrimDB;   });
								}
							)
						},
						'freeSynths',
						{
							if ( (msg.size < 3 ) ,
								{"~basicRendererCallback: freeSynths missing group name".warn;
									// postf("freeSynths MESS LEN: %", msg.size);

								},
								// else
								{
									var groupSym = msg [2] .asSymbol;

									satie.satieGroups[groupSym].freeAll;
									postf("basicRendererCallback: freeing all synths in % group", groupSym);
								}
							)
						},
						'setOutputMute',
						{
							//postf("~basicRendererCallback setMute: %\n", msg[2]);
							if ( (msg.size < 3 ) ,
								{"~basicRendererCallback: setOutputDIM missing value".warn;  },
								// else
								{
									if (msg [2] > 0,
										{e.volume.mute;},
										// else
										{e.volume.unmute;} );  // full muting implmentation
								}
							);
						}
					)
			});
		};




		~coreCallback = { arg msg;
			var command;
			command = msg[1];
			// postf("~coreCallback: command: %, msg: %, \n", command, msg);

			switch (command,
				'createSource',  // required args:  name uri    <optional>  group
				{
					//postf("~coreCallback: command: %, messLen: %   msg: %, \n", command, msg.size, msg);

					if ( (msg.size < 3 ) ,
						{"~coreCallback: OSCrx createSource message missing values".warn;
							postf("createSource MESS LEN: %", msg.size);

						},
						// else
						{
							var sourceName = msg[2];
							var uriName = "";
							var groupName = "";

							if (msg.size > 3,
								{
									uriName = msg[3];
							});

							if (msg.size > 4,
								{
									groupName = msg[4];
							});
							e.createSource(sourceName, uriName, groupName);
					});
				},
				'createGroup',
				{
					if ( (msg.size < 3 ) ,
						{"~coreCallback: OSCrx createGroup message missing values".warn;
							postf("createGroup MESS LEN: %", msg.size);

						},
						// else
						{
							var groupName = msg[2];
							e.createGroup(groupName);
						}
					)
				},
				'deleteNode',
				{
					if ( (msg.size < 3 ) ,
						{"~coreCallback: OSCrx deleteNode message missing values".warn;},
						// else
						{
							var nodeName = msg[2];
							// "~coreCallback: OSCrx deleteNode CALLED ".warn;

							if (e.allGroupNodes.includesKey(nodeName.asSymbol),
								{   e.removeGroup(nodeName);  },
								// else
								{
									e.deleteSource(nodeName);   });
						}
					)
				},
				'clear', {e.clearScene();},
				'connect',
				{
					if ( (msg.size < 4 ) ,
						{"~coreCallback: OSCrx connect message missing values".warn;},
						// else
						{
							var sourceName, listenerName;
							sourceName = msg[2];
							listenerName = msg[3];
							//'GOING TO CALL createCOnnection'.postln;
							e.createConnection(sourceName, listenerName);
						}
					)
				};
			);
			//"coreCallback called".postln;
		};
		~connectionCallback = { 	| args |
			var nodeName, listenerName, connectionName, type, temp, charIndex;
			var aziDeg, eleDeg, gainDB, delayMs, lpHz, hpHz, spread, distance;
			var thisSynth;
			var index;
			var halfSrate = 0.5 * s.sampleRate;
			//"connectionCallback called".inform;
			//postln("connectionCallback " ++ args);
			//postln("allGroupNodes " ++ e.allGroupNodes);

			//args.postln;
			connectionName = args[0].asString.split[4].asSymbol;   // this is terrible.  The spatOSC message format should be improved here
			type = args[0].asString.split[5].asSymbol;
			charIndex = connectionName.asString.find("->");


			nodeName = connectionName.asString.subStr(0, charIndex-1);
			//postf("~connectionCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);

			if ( e.allSourceNodes.includesKey(nodeName.asSymbol) == false,
				{
					error("*********************************");
					postf("satie4Unity.connectionCallback:  source node: %  is undefined \n", nodeName);
				},
				// else all ok
				{

					thisSynth = e.allSourceNodes[nodeName.asSymbol].at(\synth);


					switch(type,
						'update',
						{
							if ( (args.size != 7 ) ,
								{"connectionCallback: OSCrx update message missing values".warn;},
								// else
								{
									// get values from vector, and write to connectionState
									aziDeg = args[1].raddeg;
									eleDeg= args[2].raddeg;
									gainDB = args[3];
									delayMs = args[4];
									lpHz = args[5];
									distance = args[6];  // not used by basic spatializers

									//DEBUG
									//~allSourceNodes[nodeName.asSymbol].put(\outDB, gainDB);



									/*		z = (z+1).mod(20);
									if ( (z == 0), {postf("\n")});
									postf("  %  " ++ gainDB.trunc );*/


									thisSynth.set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz);
									//postf("~connectionCallback:  update: gain  % \n", gainDB);

								}
							)
						},
						'hpHz',   //  degree  (0 == noEffect,  1 == full effect)
						{
							if ( (args.size != 2 ) ,
								{"connectionCallback: OSCrx hpHz message wrong number of values".warn;},
								// else
								{
									// get value from vector, and write to connectionState
									hpHz = args[1];   // get highpass cutoff value
									thisSynth.set(\hpHz ,  clip(hpHz, 1, halfSrate ));

									//postf("~connectionCallback:  hpHz connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);

								}
							)
						},
						'spread',
						{
							if ( (args.size > 0 ) ,
								{


									// invert the spread value (usually an exp) to work with SATIE's VBAP-based spatializer (or others)
									spread = 100 *  ( 1 - (clip(args[1],0,1)));  // get values from vector, and write to connectionState

									thisSynth.set(\spread, spread);

									//postf("~connectionCallback:  SPREAD:  connectionName: %  spread: % \n", connectionName, spread);

								},
								// else
								{"~connectionCallback: OSCrx spread message with no values".warn; })
						};
					);
			});
		};
		~connectionProcessCallback = {

			| args |
			var nodeName, listenerName, connectionName, type, temp, charIndex;
			var aziDeg, eleDeg, gainDB, delayMs, lpHz, spread, distance;
			var thisGroup, thisGroupName;
			var myProcess;
			// postln("connectionProcessCallback called" ++ args ++"\n");

			//postf(" ~connectionProcessCallback \n");

			//args.postln;
			connectionName = args[0].asString.split[4].asSymbol;   // this is terrible.  The spatOSC message format should be improved here
			type = args[0].asString.split[5].asSymbol;
			charIndex = connectionName.asString.find("->");

			nodeName = connectionName.asString.subStr(0, charIndex-1);

			if ( e.allSourceNodes[nodeName.asSymbol] == nil,
				{
					warn("satie4Unity.connectionCallback:  source node: %  is undefined \n", nodeName);
				},
				// else all ok
				{

					// We know this is a sourceProcessingNode since this callback was chosen for this node
					// so by default, we will update the source's group

					thisGroupName = e.allSourceNodes[nodeName.asSymbol].at(\groupNameSym);  // process nodes have unique groups
					thisGroup = e.allGroupNodes[thisGroupName].at(\group).group;

					myProcess = e.allSourceNodes[nodeName.asSymbol].at(\process);


					//postf("~connectionProcessCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);

					switch(type,
						'update',
						{
							if ( (args.size != 7 ) ,
								{"connectionProcessCallback: OSCrx update message missing values".warn;},
								// else
								{
									// get values from vector, and write to connectionState
									aziDeg = args[1].raddeg;
									eleDeg= args[2].raddeg;
									gainDB = args[3];
									delayMs = args[4];
									lpHz = args[5];
									distance = args[6];

									if (myProcess[\updateConnection] == nil,
										{

											//postf("~connectionProcessCallback:  setting update for nodes group %\n", connectionName);
											// distance not used by standard spatializers
											thisGroup.set(\aziDeg, aziDeg, \eleDeg, eleDeg, \gainDB, gainDB, \delayMs, delayMs, \lpHz, lpHz);
										},
										// else use custom handler
										{
											// postf("~connectionProcessCallback:  calling custom update handler for %\n", connectionName);
											// distance used by custom process functions
											myProcess[\updateConnection].value(myProcess, aziDeg, eleDeg, gainDB, delayMs, lpHz, distance);
									});

								}
							)
						},
						// 'hpHz',   //  degree  (0 == noEffect,  1 == full effect)  Not implemented yet
						'spread',
						{
							if ( (args.size > 0 ) ,
								{
									//postf("~connectionProcessCallback:  connectionName: %  type: %  size: % args: %\n", connectionName, type, args.size, args);
									spread = args[1];  // get values from vector, and write to connectionState

									if (myProcess[\spread] == nil,
										{
											//postf("~connectionProcessCallback:  setting spread for node's group  %\n", connectionName);
											thisGroup.set(\spread, spread);
										},
										// else use a custom handler
										{
											//postf("~connectionProcessCallback:  calling custom spread handler for %\n", connectionName);
											myProcess[\spread].value(myProcess, spread);

									});
								},
								// else
								{"~connectionProcessCallback: OSCrx spread message with no values".warn; })
						};
					);
			});
		};
		~sourceNodeCallback = {
			| args |
			var name, type, values, eventName, state;
			name = args[0].asString.split[4].asSymbol;
			type = args[0].asString.split[5].asSymbol;

			//'~sourceNodeCallback'.postln;

			switch(type,
				'prop', {e.setProperty(name, args[1], args[2]);
					//postf("~sourceNodeCallback:  nodeName: %  setProp: %  key: % value: %\n", name, args[1], args[2]);

				},
				'uri', {e.setUri(name, args[1])},
				'event',
				{
					//postf("~sourceNodeCallback:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args);
					if ( (args.size < 2 ) ,
						{"~setEvent: OSCrx message with no values".warn;},
						{  // else
							values = args;
							eventName = args[1];
							values.removeAt(0);
							values.removeAt(0);
							e.setEvent(name, eventName, values);
						}
					)
				},
				'state',
				{
					if ( (args.size > 1) ,
						{
							state = args[1];
							e.setState(name, state);
						},
						{"~setState: OSCrx message with no values".warn; })  // else
				},
				{postf("~sourceNodeCallback:  UNMATCHED:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args)};
			);
		};

		// ~sourceProcessCallback = { "sourceProcessCallback called".warn; };
		// e.g  /spatosc/core/source/nodename/prop  key val
		// source node has unique group, updates are to source's group (to cloned synths etc)
		~sourceProcessCallback = { | args |
			var name, type, values, eventName, state, myProcess, myProcessSym;


			name = args[0].asString.split[4].asSymbol;
			type = args[0].asString.split[5].asSymbol;

			//myProcessSym = ~allSourceNodes[name.asSymbol].at(\process);
			//myProcess = self.allProcesses[myProcessSym];
			myProcess = e.allSourceNodes[name.asSymbol].at(\process);

			//'~sourceProcessCallback'.postln;


			switch(type,
				'prop',
				{
					if (myProcess[\prop] == nil,
						{
							var groupName = e.allSourceNodes[name.asSymbol].at(\groupNameSym);

							//postf("~sourceProcessCallback: send PROP to group:  nodeName: %  group: %   \n", name,groupName);

							e.setGroupProperty(groupName, args[1], args[2]);
						},
						// else use custom handler
						{
							//postf("~~sourceProcessCallback:  calling custom prop handler for %\n", name);
							myProcess[\prop].value(myProcess,  args[1], args[2]);
					});
				},

				'uri',  // not used:  process synths are defined in the process class, or set by events
				{
					// ~setUri.value(name, args[1])

				},
				'state',    // not used
				{
				},
				'event',
				{
					//postf("~sourceProcessCallback:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args);
					if ( (args.size < 2 ) ,
						{"~sourceProcessCallback event: OSCrx message with no values".warn;},
						{  // else
							values = args;
							eventName = args[1];
							values.removeAt(0);
							values.removeAt(0);


							// NOTE:  event names for processes are either:
							//  \setParam (to the state of a process param)
							// or
							// allOtherNames (to call a function with an arg vec)
							if (( eventName == \setParam)&& (values.size == 2),
								{
									// postf("sourceProcessCallback event_setParam: %  % \n", values[0].asSymbol, values[1]);
									myProcess[values[0].asSymbol] = values[1] ;

								},
								// else  it is a function call
								{
									//postf("~sourceProcessCallback: event_function call:  nodeName: %  event: %  size: % args: %\n", name, eventName.asSymbol, values.size, values);
									myProcess[eventName.asSymbol].value(myProcess, values);   // call the process corresponding method passing argVec
							});
					});
				},
				{postf("~sourceProcessCallback:  UNMATCHED:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args)};
			);
		};


		//~groupCallback = { "groupCallback called".warn;};

		// e.g  /spatosc/core/group/nodename/prop  key val
		~groupCallback = {
			| args |
			var name, type, values, eventName, state;
			name = args[0].asString.split[4].asSymbol;
			type = args[0].asString.split[5].asSymbol;

			//'~groupCallback'.postln;

			switch(type,
				'prop',
				{
					//~setProperty.value(name, args[1], args[2])

					//postf("~groupCallback:  nodeName: %  setProp: %  key: % value: %\n", name, args[1], args[2]);
					e.setGroupProperty(name, args[1], args[2]);

				},
				'uri',
				{
					//postf("~groupCallback:  nodeName: %  setUri: %  \n", name, args[1]);
					// ~setUri.value(name, args[1])


				},
				'event',
				{
					postf("~groupCallback:  nodeName: %  set event: %  size: % args: %\n", name, type, args.size, args);
					if ( (args.size < 2 ) ,
						{"~setEvent: OSCrx message with no values".warn;},
						{  // else
							values = args;
							eventName = args[1];
							values.removeAt(0);
							values.removeAt(0);
							e.setGroupEvent(name, eventName, values);
						}
					)
				},
				'state',
				{
					if ( (args.size > 1) ,
						{
							state = args[1];
							//eventName = args[1];
							//~setState.value(name, state);
							postf("~groupCallback:  node: %  set state: % \n", name, state);
						},
						{"~groupCallback: OSCrx message with no values".warn; })  // else
				},
				'add',
				{
					postf("~groupCallback:  nodeName: %  add member: %  \n", name, args[1]);
					e.addMember(name, args[1])


				},
				'drop',
				{
					postf("~groupCallback:  nodeName: %  drop member: %  \n", name, args[1]);
					e.dropMember(name, args[1])


				},{postf("~groupCallback:  UNMATCHED:  nodeName: %  mesageType: %  size: % args: %\n", name, type, args.size, args)};
			);
		};


		~createSource = {| self, sourceName, uriPath , groupName = \default |
			//"createSource called".inform;
			if (self.allSourceNodes.includesKey(sourceName),
				{
					postf("~createSource:   % exists, no action \n", sourceName);
				},
				// else create new node
				{
					var type;
					type = self.getUriType(uriPath);

					if ( type == "process",  {
						self.createSourceProcess(sourceName.asSymbol, uriPath,groupName );
					},
					// else
					{
						self.createSourceNode(sourceName.asSymbol, uriPath,groupName );
					});
				}
			);
		};

		// ~createSourceProcess = { "createSourceProcess called".warn;};


		// called for uri type process://
		//error check uriName done before call this, uriPath will be a process name
		// ignore groupName since a unique one will be generated for this node and its clones
		//  uri path may include arguments
		// eg. uriPath:  "process://sheefa arg1 1.1 arg2 2.2 arg3"

		~createSourceProcess = { | self, sourceName, uriPath , groupNameDummy = \default |
			var temp, type, charIndex, processName, processClone, myProcess, cloneGroup, cloneGroupName;
			var argsString = "";
			var stringArray;
			var rawArgVec = nil;
			var argList = List[];

			//("~createSourceProcess:  URI"++uriPath).postln;

			// sheefa = uriPath;

			stringArray = uriPath.asString.split($ );
			charIndex = stringArray[0].asString.find("://");
			processName = stringArray[0].asString.subStr(charIndex+3);
			argsString = uriPath.asString.subStr(stringArray[0].size+1);
			rawArgVec= argsString.asString.split($ );

			// make list of items in argString
			rawArgVec.do( { arg item;
				if ( item != "",
					{
						argList.add(item);
				});
			});


			if (self.allProcesses[processName.asSymbol] == nil,
				{
					postf("~createSourceProcess: undefined process name:"++processName++"   ,  node not created \n");
				},
				// else ALL GOOD,  instantiate
				{
					if (self.allSourceNodes[sourceName.asSymbol]  != nil,
						{
							error("~createSourceProcess source Process node: %,   ALREAYD EXISTS \n", sourceName);
						},
						// else node good to go
						{
							postf("~createSourceProcess nodeName: %,   process name: %  URI: % \n", sourceName, processName, uriPath);
							//postf("~createSourceProcess: %:  uri: %  group: %\n", sourceName, uriPath, groupName);

							self.allSourceNodes[sourceName.asSymbol] = Dictionary();   // create node  -- create node-specific dict.
							self.allSourceNodes[sourceName.asSymbol].put(\plugin, \nil);

							// generate groupName unique to source node
							cloneGroupName = sourceName ++ "_group";
							cloneGroup = self.createGroup(cloneGroupName.asSymbol);   // create group for this node and its clones

							//cloneGroup.postln;

							// clone a new copy of the process
							temp = self.allProcesses.at(processName.asSymbol);
							processClone = temp.copy;
							//processClone[\nodeName]=sourceName.asSymbol;

							cloneGroup = self.allGroupNodes[cloneGroupName.asSymbol].at(\group); // must be called after createGroup() above

							self.allSourceNodes[sourceName.asSymbol].put(\process, processClone);
							self.allSourceNodes[sourceName.asSymbol].put(\groupNameSym, cloneGroupName.asSymbol);

							myProcess = self.allSourceNodes[sourceName.asSymbol].at(\process);

							// send URI's argsString to setup without any error checking

							myProcess[\setup].value(myProcess, sourceName.asSymbol, cloneGroupName.asSymbol, argList );   // set the state of the process
							self.setSynth(sourceName.asSymbol, "");  // sets dummy plugin as placeholder

							//~oscInterface.sourceOSC(sourceName.asSymbol, ~sourceProcessCallback);   // create OSC callback
							osc.sourceOSC(sourceName.asSymbol, e.['sourceProcessCallback']);   // create OSC callback
							postf("~createSourceProcess: CREATED NODE: %,  with  process:  % \n", sourceName, processName);


					});
			});
		};


		~createSourceNode = { | self, sourceName, uriString , groupName = \default, argsList|
			var synthName;

			var type;

			// MAKE SURE URI STRING IS VALID -- if not, will post warning and be set to plugin://dummyPlugin
			uriString = self.checkUri(sourceName, uriString);

			type = self.getUriType(uriString);

			if (groupName == "", { groupName = \default; });   // make sure group name is ok

			// check to see if group  exists (even if the corresponding groupNode has not yet been instntiated),  if  not, create it
			if ( satie.satieGroups[groupName.asSymbol] == nil,
				{
					postf("~createSource_groupcheck:   source:%    group:  % undefined,  CREATING GROUP NOW \n", sourceName, groupName);
					self.createGroup(groupName.asSymbol);
				}
			);

			postf("~createSourceNode: %:  uri: %  group: %\n", sourceName, uriString, groupName);
			self.allSourceNodes[sourceName.asSymbol] = Dictionary();   // create node  -- create node-specific dict.
			self.allSourceNodes[sourceName.asSymbol].put(\plugin, \nil);
			self.allSourceNodes[sourceName.asSymbol].put(\uriStr, uriString);

			// now set node's group
			self.allSourceNodes[sourceName.asSymbol].put(\groupNameSym, groupName.asSymbol);

			// call  setSynth to complete instance creation
			// note:  setSynth acts on URI

			if ( ( (type != "plugin") &&  (type != "effect") ),
				{
					error("~createSourceNode: BUG FOUND IN CODE:   URL SHOULD BE OK" );
					self.setSynth(sourceName.asSymbol, \dummyPlugin);
				},
				// else  // path format ok, proceed
				{
					synthName = self.getUriName(uriString);
					self.setSynth(sourceName.asSymbol, synthName);
			});
			osc.sourceOSC(sourceName.asSymbol, e.['sourceNodeCallback']);   // create OSC callback
			//"createSourceNode called".inform;
		};

		//~createGroup = { "createGroup called".warn;};
		// returns group
		~createGroup = { |self,  groupName |

			if (self.allGroupNodes.includesKey(groupName),
				{
					postf("createGroup:  GroupNode % exists, no action \n", groupName);
					self.allGroupNodes[groupName.asSymbol].at(\group);  // return group
				},
				// else create new group node
				{
					var group;

					if (satie.satieGroups[groupName.asSymbol] != nil, // group already exists in SATIE, no need to create it
						{
							group = satie.satieGroups[groupName.asSymbol];
						},
						// else  group does not exist in SATIE,  create it
						{
							group = satie.makeSatieGroup(groupName.asSymbol);
							if ( groupName.asSymbol == \default,
								{
									postf("~createGroup:  BUG FOUND-- SHOULD NOT HAVE TO INSTANITATE DEFAULT GROUP !!!!");
							});
					});

					postf("~createGroupNode:   % \n", groupName);
					self.allGroupNodes[groupName.asSymbol] = Dictionary();   // create node  -- create node-specific dict.
					self.allGroupNodes[groupName.asSymbol].put(\group , group);  // save group
					self.allGroupNodes[groupName.asSymbol].put(\groupSym , groupName.asSymbol);  // save group name symbol
					self.allGroupNodes[groupName.asSymbol].put(\members, List() );  // create dict for members
					self.allGroupNodes[groupName.asSymbol].put(\plugin, \nil);

					//  set group
					self.allGroupNodes[groupName.asSymbol].put(\group, group );

					//~oscInterface.groupOSC(groupName.asSymbol, ~groupCallback);   // create OSC callback for this source
					osc.sourceOSC(groupName.asSymbol, e.['groupCallback']);   // create OSC callback

					group;  // returns groups
				}
			);
		};

		~createConnection = { |self, sourceName, listenerName |

			var connectionName, myProcess;
			//postf("createConnection:  for source % and listener % \n", sourceName, listenerName);

			connectionName = sourceName ++ "->" ++ listenerName;
			myProcess = nil;


			if ( self.allSourceNodes.includesKey(sourceName.asSymbol) == false,
				{
					error("*******************");
					postf("bug:  satie4Unity.createConnection: node % not defined, can not establish connection \n", sourceName.asString);
				},
				// else
				{
					myProcess = self.allSourceNodes[sourceName.asSymbol].at(\process);

					if ( self.allSourceNodes[sourceName.asSymbol].includesKey(\connectionName),
						{
							'~createConnection:  connection already exists, no action taken'.postln;
						},
						// else create new one,  and a corresponding OSC callback
						{
							self.allSourceNodes[sourceName.asSymbol].put(\connectionName, connectionName.asSymbol);

							// is this a processNode ?
							if ( myProcess != nil,
								{
									postf("~createConnection: creating Custom update callback for  %  \n", sourceName.asSymbol);
									osc.connectionOSC(self.allSourceNodes[sourceName.asSymbol].at(\connectionName), e.['connectionProcessCallback']);
								},
								//else  regular source node, set up standard connection callback
								{
									osc.connectionOSC(self.allSourceNodes[sourceName.asSymbol].at(\connectionName), e['connectionCallback']);
							});

							// postf("~createConnection: creating callback for  %  ", ~allSourceNodes[sourceName.asSymbol].at(\connectionName));
					});
			});
		};

		~setSynth = { 	| self, nodeName, pluginName |
			var validPluginName = pluginName;
			var sourceNode = self.allSourceNodes[nodeName.asSymbol];
			var groupName = sourceNode.at(\groupNameSym);
			var type;
			var inBus;

			var uriPath = sourceNode.at(\uriStr);

			type = self.getUriType( uriPath );


			//postf("~setSynth: node: %   uriStr: %  type: % \n",  nodeName, uriPath,   type);

			//postf("~setSynth: node: %    NEW: %  CURRENT: % \n", nodeName, pluginName.asSymbol, self.allSourceNodes[nodeName.asSymbol].at(\plugin).asSymbol);


			// NEED A REAL SYNTH DEF CHECK HERE- set the \dummyPlugin if it fails
			if ( validPluginName.asString == "", { validPluginName = \dummyPlugin; });


			if (validPluginName.asSymbol != self.allSourceNodes[nodeName.asSymbol].at(\plugin).asSymbol,
				{
					var synth;

					// check to see if a synth has already been allocacted, if so, kill it
					if  ( self.allSourceNodes[nodeName.asSymbol].at(\synth) != nil,
						{
							'~setSynth: REPLACE EXISTING SYNTH'.postln;
							satie.cleanInstance(nodeName.asSymbol,groupName.asSymbol );
					});

					sourceNode.put(\plugin, validPluginName.asSymbol);


					if ( ( (type == "effect") || (groupName == \effect) ),
						{
							inBus = self.getFxInBus(uriPath);
							postf("~setSynth: assigning inBus: % to effects node % \n", satie.aux[inBus] , nodeName);
							synth = satie.makeInstance(nodeName.asSymbol, validPluginName.asSymbol, \effect, [\in, satie.aux[inBus] ]);
						},
						// else
						{
							synth = satie.makeInstance(nodeName.asSymbol, validPluginName.asSymbol, groupName.asSymbol);
					});


					sourceNode.put(\synth, synth);
				},
				{
					//postf("~setSynth: ignoring set plugin % for node % : plugin already set \n", pluginName, nodeName);
				}
			);
			//"setSynth called".inform;

		};


		// valid URIs:   process://name  args
		//	 effect://synthName   <opt> inBus n     // defaults to  inBus=0
		// plugin://synthName
		~setUri = { | self, nodeName, uriPath |
			var charIndex, type, temp;
			var synthName = \dummyPlugin;  // default
			var node = self.allSourceNodes[nodeName.asSymbol];
			var inBus;

			uriPath = self.checkUri(nodeName, uriPath);     // make sure uri is valid, otherwise assigns to "plugin://dummyPlugin"
			node.put(\uriStr, uriPath);

			type = self.getUriType(uriPath);

			//postf("~setUri nodeName: %, type: %  plugName: %\n", synthName, type, uriPath);
			// still needs to be expanded for soundfiles, adc, web etc..

			switch( type,
				"plugin", {
					synthName = self.getUriName(uriPath);
				},
				"effect", {
					synthName = self.getUriName(uriPath);
				}
			);
			self.setSynth(nodeName.asSymbol, synthName);
		};


		~setProperty = { | self, nodeName, property, value |
			var thisSynth = self.allSourceNodes[nodeName.asSymbol].at(\synth);
			//"setProperty called".inform;
			//postf("~setProperty: seting % of % to %\n", property, nodeName, value);

			thisSynth.set(property.asSymbol, value);
		};

		~setGroupProperty = { | self, groupName, property, value |
			var group = self.allGroupNodes[groupName.asSymbol].at(\group).group;

			//postf("~setGroupProperty: seting % of % to %\n", property, groupName, value);

			group.set(property.asSymbol, value);
		};


		~setState = { | self, nodeName,  state |
			var thisSynth = self.allSourceNodes[nodeName.asSymbol].at(\synth);

			thisSynth.run(state);


			if (self.debugFlag, {postf("~setState: seting state of % to %\n", nodeName, state)});
		};

		// events RX:   /spatosc/core/source/nodename/event eventName v1...vN
		~setGroupEvent = { | self, groupName, eventName,  args |
			var valueCount = args.size;
			var group = self.allGroupNodes[groupName.asSymbol].at(\group).group;

			postln("~setGroupEvent: node:" ++groupName ++" event name:"++eventName++"  arg(s): "++ args );

			if ( (valueCount > 1) ,    // pass vector
				{
					group.set(eventName.asSymbol, args);
				},
				// else
				{
					if ( (valueCount == 1) ,    // pass value
						{
							group.set(eventName.asSymbol, args[0]);
						},
						// else  no args.. just pass 1
						{
							group.set(eventName.asSymbol, 1);
						}
					);
			});
		};






		~setEvent = { | self, nodeName, eventName,  args |
			var valueCount = args.size;
			var thisSynth = self.allSourceNodes[nodeName.asSymbol].at(\synth);

			// DEBUG
			//var db = ~allSourceNodes.at( nodeName.asSymbol).at(\outDB);
			//"setEvent called".inform;


			if ( (valueCount > 1) ,    // pass vector
				{
					// DEBUG
					//postln("~setEvent: " ++ nodeName.asSymbol ++ "    args: " ++ args  );
					//if( args[2] < 0.07, {postln("~setEvent: " ++ nodeName.asSymbol ++ "   INCIDENCE  " ++ args[2]  )});

					thisSynth.set(eventName.asSymbol, args);
				},
				// else
				{
					if ( (valueCount == 1) ,    // pass value
						{
							// DEBUG
							// postln("~setEvent: " ++ nodeName.asSymbol ++ "        BANG\n");

							thisSynth.set(eventName.asSymbol, args[0]);
						},
						// else  no args.. just pass 1
						{
							"no args to setEvent".warn;
							thisSynth.set(eventName.asSymbol, 1);
						}
					);
			});
		};

		//~addMember = { "addMember called".warn;};
		~addMember = { | self,  groupName, nodeName |
			var memberList = self.allGroupNodes[groupName].at(\members);
			var group = self.allGroupNodes[groupName].at(\group).group;
			//


			// check to see if member is already in group

			// if not add it
			// satie.changeGroup(groupName, nodeName);   // assign source node to group's proxySpace
			//  self.allSourceNodes[nodeName.asSymbol].put(\group, groupProxy);
			memberList.add(nodeName.asSymbol);


			postf("~addMember: group % adding member %\n", groupName, nodeName);
			// ~groupCopyState(groupName, nodeName);
		};


		//~dropMember = { "dropMember called".warn;};

		~dropMember = { |self  groupName, memberName |
			var memberList = self.allGroupNodes[groupName].at(\members);
			var memberNameSym = memberName.asSymbol;
			var index = -1 ;

			memberList.do({ arg item, i;
				if ( item == memberNameSym,
					{ index = i });

			});
			if (index > -1,
				{
					memberList.removeAt(index);
					memberList.postln;
					postf("~~dropMember: group % dropping member %\n", groupName, memberName);
				},
				// else
				{
					postf("~dropMember: group % member % not found \n", groupName, memberName);
			});
		};

		~clearScene = {  | self |
			var nodelist = self.allSourceNodes.keys;
			"clearScene called".warn;
			//'CLEARING SCENE'.postln;

			// first flush all nodes
			self.allSourceNodes.keysDo { |key |
				//key.postln;
				self.clearSourceNode(key);
			};

			self.allSourceNodes.clear();
			self.allSourceNodes.size;

			// do not clear all groups except default group

			/*		satie.satieGroups.keysDo{ |key |
			var nodeSym = key;

			if (key != \default,
			{
			satie.killSatieGroup(key);
			});
			};*/

		};
		~deleteSource = { | self, nodeName |
			//"deletaSource called".inform;
			if ( self.allSourceNodes.includesKey(nodeName.asSymbol) ,
				{
					// if its a sourceProcessNode do this first


					self.clearSourceNode(nodeName.asSymbol);
					//'REMOVE NODE'.postln;
					self.allSourceNodes.removeAt(nodeName.asSymbol);     // remove node from global dictionary
			});
		};
		~removeGroup = { | self, groupName |
			"removeGroup called".inform;
			if ( self.allGroupNodes.includesKey(groupName.asSymbol) ,
				{
					//  No OP  ~clearGroupNode.value(groupName.asSymbol);
					postf("~removeGroup:  group node: % \n",  groupName);
					self.allGroupNodes.removeAt(groupName.asSymbol);     // remove node from global dictionary
			});
		};
		~clearGroupeNode = { | self, nameSym |
			var node = self.allGroupNodes[nameSym];
			//var connectionName = node.at(\connectionName);
			var nodeKeys = node.keys;
			var thisGroup = self.allGroupNodes[nameSym].at(\group);
			var memberList = self.allGroupNodes[nameSym].at(\members);
			"clearGroupNode called".inform;


			//~cleaninstance(nameSym, thisGroup);

			postf("~clearGroupeNode:  group node: % \n",  nameSym);

			// disconnect callbacks

			osc.removeGroupOSC(nameSym);
			//  clear node's local dictionary
			// maybe this is unnecessary

			memberList.clear();

			nodeKeys.do { | key |
				postf("removing node keys:  node: %   key %  \n",  nameSym, key);
				node.removeAt(key);
			};
		};

		~clearSourceNode = {  | self, nameSym |
			var node = self.allSourceNodes[nameSym];
			var connectionName = node.at(\connectionName);
			var nodeKeys = node.keys;
			var thisGroupName = self.allSourceNodes[nameSym].at(\groupNameSym);
			//"clearSourceNode called".inform;

			//self.allSourceNodes[nameSym].postln;

			// is this a process node?
			if ( self.allSourceNodes[nameSym].at(\process) != nil,
				{
					var groupSym =  self.allSourceNodes[nameSym].at(\groupNameSym);

					var myProcess = self.allSourceNodes[nameSym].at(\process);



					// now kill off the clones in that group
					//myProcess.at(\nodeGroupProxy).free;

					myProcess.cleanup();   // frees any state the process may have created, i.e. synths

					//  IF THE SYNTH IS NOT CLEANED FROM THE NODE TREE, DO THE SAME AS THE REGULAR SOURCE CASE BELOW
					satie.cleanInstance(nameSym,thisGroupName );

					// now delete group
					self.removeGroup(groupSym); //
					satie.killSatieGroup(groupSym);   // kill the group, since it was unique to this source
				},
				// else  its just a regular source
				{
					var synth = satie.satieGroupInstances[thisGroupName][nameSym];
					satie.cleanInstance(nameSym,thisGroupName );
					synth.free;    // to make sure it gets cleaned from the node tree
					if (self.debugFlag, {postf("clearSourceNode: delete  node  % in group %\n", nameSym, thisGroupName);});

			});

			//postf("~clearing:  node: % and connection: %\n",  nameSym, connectionName);

			// disconnect callbacks
			if (node.includesKey(\connectionName),
				{
					osc.removeConnectionOSC( node.at(\connectionName).asSymbol );
			});

			osc.removeSourceOSC(nameSym);
			//  clear node's local dictionary
			// maybe this is unnecessary
			nodeKeys.do { | key |
				//postf("removing node keys:  node: %   key %  \n",  nameSym, key);
				node.removeAt(key);
			};
		};

		~getUriName = { |  self, uriPath |
			var stringArray = uriPath.asString.split($ );
			var charIndex = uriPath.asString.find("://");
			var temp = uriPath.asString.subStr(charIndex);
			var uriName = temp.asString.replace("://", "");

			uriName.asString.split($ )[0].asString;
		};

		~getUriType = { | self, uriPath |
			var charIndex, uriName, type, temp;

			type = "";

			// type://name (i.e. plugin://DustDust, file://<path>

			// check URI name to make sure its valid

			if (uriPath.asString.contains("://") == false,
				{
					if (uriPath.size > 0, {warn("~getUriType:  uri type format error: % ", uriPath);});
				},

				// else  // path ok, proceed
				{
					charIndex = uriPath.asString.find("://");

					temp = uriPath.asString.subStr(charIndex);
					type = uriPath.asString.subStr(0, charIndex-1);
					uriName = temp.asString.replace("://", "");
			});
			type;
		};

		~getUriArgs = { |self, uriPath  |
			var temp,charIndex, processName;
			var argsString = "";
			var stringArray;
			var rawArgVec = nil;
			var argList = List[];

			//("~getUriArgs:  URI: "++uriPath).postln;

			// sheefa = uriPath;

			stringArray = uriPath.asString.split($ );

			if (stringArray.size < 2,
				{
					[];
				},
				{

					charIndex = stringArray[0].asString.find("://");
					processName = stringArray[0].asString.subStr(charIndex+3);

					argsString = uriPath.asString.subStr(stringArray[0].size+1);

					//argsString.postln;

					rawArgVec= argsString.asString.split($ );
					// make list of items in argString
					rawArgVec.do( { arg item;
						if ( item != "",
							{
								argList.add(item);
						});
					})
			});
		};

		// no error checking, must not be called on empty node, or non-effects-type node
		// uriPath  eg:   effect://reverb satieAuxBus 3
		~getFxInBus = { | self, uriPath |
			var synth;
			var auxBus = 0;  //default bus
			var satieBus;


			var argList = self.getUriArgs(uriPath);

			//("~getFxInBus:  URI: "++uriPath).postln;


			// if there are two args, and the first arg is the keyword "inBus"then try to set the effect's \in param to the second arg
			if (argList.size > 1,
				{
					if (argList[0].asString == "inBus",
						{
							auxBus = argList[1].asInt.clip(0, self.satieAuxBusCount-1);
					});
			});

			auxBus;  // returns auxBus for effects node

			//	satieBus = satie.aux[auxBus];
			//synth = self.allSourceNodes[nodeName.asSymbol].get(\synth);
			//synth.set(\in, auxBus);
			//synth.set(\in, satieBus );
			//postf("~setFxInBus: setting Aux Bus in %   % for effects node % \n", auxBus, uriPath, nodeName);
		};


		// if URI is ok, returns uriString, else   "plugin://dummyPlugin"
		~checkUri = { | self, nodeName, uriString |
			var type = self.getUriType(uriString);

			//uriString.postln;
			if ( (type != "plugin") && (type != "effect"),
				{
					error("~checkUri:  node: %  bad URI: % , using default: plugin://dummyPlugin \n", nodeName, uriString);

					"plugin://dummyPlugin"
				},
				{
					uriString;
			});
		};

		// DEBUGGING FUNCTIONS
		~dumpConnections = { 	| self |
			var undefined = 0;

			self.allNodes.keysDo { |key |
				var nodeSym = key;
				postf("node: %  :   ", key);
				postf("\t : node:   %  connectionName:    % \n",  key, self.allNodes[nodeSym].at(\connectionName));

			};
		};

		~dumpNodes = { 	| self |
			var connections = 0;
			self.allSourceNodes.keysDo { |key |
				var nodeSym = key;
				postf("node: %  \n", key);
				self.allSourceNodes[nodeSym].keysDo { | key |
					postf("\t : %  =  % \n",  key, self.allSourceNodes[nodeSym].at(key));
				};
			};
		};

		~dumpGroups = { 	| self |

			postf("~dumpGroups: %  groups defined via OSCrx: \n", self.allGroupNodes.size);
			self.allGroupNodes.keysDo { |key |
				var nodeSym = key;
				var memberList = self.allGroupNodes[nodeSym].at(\members);

				postf("Group node: %  members: \n", nodeSym);
				memberList.do { | key |
					postf("\t : %  \n",  key);
				};

				postf("node: %  \n", key);
				self.allGroupNodes[nodeSym].keysDo { | key |
					postf("\t : %  =  % \n",  key, self.allGroupNodes[nodeSym].at(key));
				};
			};
		};

		// DEPRICATED
		~globalSetState = { "globalSetState has been depricated".warn;};
		~globalSet = { "globalSet  has been depricated".warn;};
		~isFXuri = {"isFXuri has been depricated".warn;};

	}); // Environment.make
	"satie4unityprotol loaded".inform;
	e.know = true;
	postf("passed osc env: %\n", osc);
	// osc.newOSC(oscID, e['coreCallback'], "/SATIE");
	osc.removeBasicRendererOSC(\createSoundSource);

	osc.newOSC(\createSoundSource, e['coreCallback'], "/spatosc/core");

	osc.removeBasicRendererOSC(\brOSC);
	osc.basicRendererOSC(\brOSC,e['basicRendererCallback']);
	e;
};


// uncomment only for debugging
//~satie4unity = ~satie4unityprotocol.value(~oscInterface, ~scbr);

)