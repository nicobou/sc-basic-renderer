// s.makeGui;
// s.meter;
// s.sampleRate;

//~dumpNodes.value();


//gainDB = -90, delayMs = 1, lpHz = 15000, hpHz = 1, spread = 1

~bell = ~scbr.satieGroupInstances[\oceanScene][\bellSnd_6];




SynthDef(\prayer_bell,  ~function  ).add;
(

~bell.free;

~bell =Synth.new("prayer_bell",  [ \i_doneAction, 0, \decayscale , 0.7,  \muteSecs, 0, \gainDB, 0]);

~bell.set(\note, #[61, 1, 1]);
)

~bell.set(\t_trig, 1);



~bell.set(\gainDB, 0);



// ~bell.set(\note, #[61, 0.9, -1]);


~bell.set(\note, #[61, 1, 1]);
~bell.set(\t_trig, 1);

~bell.set(\note, #[61, 0.0, 0.3]);
~bell.set(\t_trig, 1);




~bell.set(\amp, 1);


~bell.set(\decayscale , 0.7,   \muteSecs, 0)

~bell.set(\t_trig, 1);
~bell.set(\decayscale, 0.6);









(

~bell.set(\note, #[61, 0.9, 0.9], \t_trig, 1);

~bell.set(\t_trig, 1);
~bell.set(\decayscale, 0.1);
~bell.set(\gainDB, 0);

)






~nodeName = \coreLoopBuff;
~nodeName2= \accLoopBuff;
~noteName3 = \accentsLoopBuff;



~scbr.satieGroups[\whaleBellyScene].set(\note, #[60,0,0]);

~scbr.satieGroups[\whaleBellyScene].set(\note, #[60,1,0]);



~node = ~scbr.satieGroupInstances[\whaleBellyScene][\coreLoopBuff];


~node.set(\note, #[60,1,1]);
~node.set(\amp, 6);

~node.set(\transp, -0);

~node.set(\transp, -2);





~satie4unity.deleteSource(\bellSnd_1);

~scbr.satieGroups[\oceanScene]


~satie4unity.satieAuxBusCount;



~satie4unity.clearScene()

~satie4unity.allSourceNodes.size()



~scbr.satieGroups[\oceanScene].freeAll;

~scbr.killSatieGroup(\oceanScene)


~scbr.satieGroupInstances[\oceanScene].size()

~scbr.satieGroupInstances[\default][\vStem_61].dump


bad values:  15, 26, 29,51, 56,84, 95,


~scbr.cleanInstance("bellSnd_3".asSymbol ,\oceanScene );



~scbr.cleanInstance("bellSnd_5".asSymbol ,\oceanScene );




~bell.free

~scbr.satieGroupInstances[\default]


~scbr.satieGroupInstances[\default][vStem_63].free

~scbr.satieGroupInstances[\default][\vStem_18].set(\curve, 6, \warp, 5, \glide, 0, \note, #[60, 1, 1] );

~scbr.satieGroupInstances[\default][\vStem_18].set(\glide, 0, \transp, 0, \startLoop, 0, \endLoop, 999999, \bufnum, b.bufnum, \note, #[60, 1, 1] );

~scbr.satieGroupInstances[\default][\vStem_18].set(\bufnum, b.bufnum);


~aqPlayBuffers["vortexDrone.aif".asSymbol]

b



~scbr.satieGroupInstances[\oceanScene][\bellSnd_2].free



~scbr.makeInstance(\sheefa, \busgverb, \effect);

~scbr.makeInstance(\sheefa, \busgverb, \default);

		if ( ~scbr.satieGroups[\effect] == nil,
			{~effectProx = ~scbr.makeSatieGroup(~satieFXgroupSym, \addToTail);}
		);


~satie4unity.allGroupNodes.size()


~scbr.aux.size
"sheefa".size


(

~cloneParams =[ \note, [ 60, 1, 1 ], \t_trig, 1 ];

~synthName="drops-95.wav:k:rev".asSymbol;
x = ~scbr.makeKamikaze(\sheefa, ~synthName, \default, ~cloneParams);
// x = ~scbr.makeInstance(\sheefa, ~synthName, \default);
x.set(\gainDB, 0);
x.set(\t_trig, 1);
)


(

~cloneParams =[ \gainDB, 0, \note, [ 60, 1, 1 ], \t_trig, 1 ];

~synthName="drops-95.wav:k:rev".asSymbol;
x = ~scbr.makeKamikaze(\sheefa, ~synthName, \default, ~cloneParams);

)


	~zombieTrig1_instances.keysDo{ arg key;

		if ( key == ~processName,
			{
				key.postln;
				~satie4unity.allProcesses.at(~processName).at(\synthCountMax).postln;
		});
	};





(
~cloneParams =[ \gainDB, 0, \note, [ 60, 1, 1 ], \t_trig, 1 ];

~synthName="drops-95.wav:k:rev".asSymbol;

~incr= 0;

{100.do{ arg item;
var n = item + ~incr;

	~cloneParams =[ \gainDB, 0, \note, [ 60, (0.3 + (0.7*item)/100),  item/100 ], \t_trig, 1 ];

// ~synthName="drops-"++ n++".wav:k:rev".asString;
x = ~scbr.makeKamikaze(\sheefa, ~synthName, \default, ~cloneParams);






	//n.postln;
			0.1.wait;
};}.fork


)


"_______"




~scbr.satieGroupInstances[\default][\digestion].set(\gainDB, -10);



~scbr.satieGroupInstances[\default][\digestion].run(0);


~scbr.satieGroupInstances[\default][\sound].set(\loop, 1);

~scbr.satieGroupInstances[\default][\sound].set(\gainDB, -60.1);

TempoClock.default.sched(0.05,
									{
~scbr.satieGroupInstances[\default][\sound].set(\gainDB, -60.1);

~scbr.satieGroups[\default].set(\gainDB,  -30);

										nil });




~scbr.satieGroupInstances[\default][\sound].set(\gainDB, -30);



~satie4unity.allSourceNodes[\srcNodeSP].at(\groupNameSym);


~satie4unity.allSourceNodes[\srcNodeSP];

~myGroupName = \srcNodeSP_group;

g = ~scbr.satieGroups[~myGroupName].set(\delayMs, 200, \attackDB, -44);


g = ~scbr.satieGroups[~myGroupName].run(true);

~nodeName= \bellSnd_8;


~satie4unity.setEvent(~nodeName, \note, [80,1,1]);
~satie4unity.setEvent(~nodeName, \t_trig, 1);







~groupSym = \default;

~nodeName= \bellSnd_8;
~nodeName = \setNodeSP;

~nodeGroupName = ~satie4unity.allSourceNodes[~nodeName.asSymbol].at(\groupNameSym);

~listenerName = "listener";

~allGroupNodes.includesKey(~nodeGroupName);

~cloneName = ~nodeName++"_0";


// process node testing
~myProcess = ~allSourceNodes[~nodeName.asSymbol].at(\process);
~myGroupName = ~myProcess.nodeGroupName.asSymbol;
~myGroup = ~myProcess.nodeGroup.group;



// for normal source Node
//~pluginName = "pbell1";
//~pluginPath = "plugin://"++~pluginName;

// for process node
~pluginName = "sheefa";
//~pluginPath = "process://"++~pluginName;


/*
~createSource.value(~nodeName, ~pluginPath, ~groupSym);
~createConnection.value(~nodeName,~listenerName);

*/

// inspect values
~myProcess.at(\cloneCount);
~myProcess.at(\triggerIntervalMs);
~myProcess.at(\nodeGroup);

//~someKey = "cloneCount";
//~myProcess.put(~someKey.asSymbol, 33);


	~scbr.satieGroups[~nodeGroupName].set(\c1, 0.7,  \c3, 3, \fb,  100);


~particule1_instances.do{ |item |
	var groupName = item.nodeGroupName;

	~scbr.satieGroups[groupName].set(\c1, 2,  \c3, 4, \fb,  100);

};

	~scbr.satieGroups[groupName].set(\c1, 0.7,  \c3, 3, \fb,  100);

// 0.7, 3, 100



// srcNode_0_group, srcNode_0_6

~scbr.satieGroupInstances[~myGroupName][~cloneName].set(\note, [75,1,1], \t_trig, 1);
~myProcess.put(triggerIntervalMs, 0);

~scbr.satieGroupInstances[~myGroupName][~cloneName].set(\t_trig, 1);

~scbr.satieGroupInstances[~myGroupName][~cloneName].set(\cloudSpread, 2);


~myGroup.set(\randTrigMaxMs, 0);
//~myGroup.set(\t_trig, 1).free

\srcNode_0
~scbr.satieGroups[~myGroupName].set(\aziDeg,  -89, \eleiDeg,  0, \gainDB, -30, \note, [75,1,1], \t_trig, 1);

~scbr.satieGroups[~myGroupName].set(\cloudAziScale,  1, \cloudElevScale,  0, \t_trig, 1);
~scbr.satieGroups[~myGroupName].set(\cloudAziScale,  0, \cloudElevScale,  0, \t_trig, 1);


~scbr.satieGroups[~myGroupName].group.set(\t_trig, 1);

{~scbr.satieGroupInstances[~myGroupName].keysDo{ |key |
	var nodeSym = key;
	// var synthName = "srcNode_"++item++"_group";


	~scbr.satieGroupInstances[~myGroupName][key].set(\randTrigMaxMs, 0);
	~scbr.satieGroupInstances[~myGroupName][key].set(\note, [89,1,1]);

	~scbr.satieGroupInstances[~myGroupName][key].set(\t_trig, 1);
	key.postln;
			0.2.wait;
};}.fork



~connectionName = ~nodeName++ "->"++~listenerName;




~myGroupName;

// clear
//~myProcess[\clearSynths].value(~myProcess);

//~myProcess.freeClones();


//~scbr.cleanInstance(~cloneName,~myGroupName );


~allSourceNodes[\ball_5].at(\groupNameSym);


\srcNode_0

~scbr.satieGroups[\srcNode_group];
~scbr.satieGroups[\srcNode_1_group].set(\randTrigMaxMs, 0);



~scbr.satieGroups[\srcNode_0_group].set(\aziDeg,  90);
~scbr.satieGroups[\srcNode_0_group].set(\t_trig, 1);

~scbr.satieGroups[\srcNode_1_group].set(\aziDeg,  -90);
~scbr.satieGroups[~myGroupName].set(\t_trig, 1);



~srcNode_0process = ~allSourceNodes[\srcNode_0].at(\process);
~srcNode_1process = ~allSourceNodes[\srcNode_1].at(\process);


~srcNode_0process.at(\nodeGroup).set(\aziDeg,  -90);
~srcNode_1process.at(\nodeGroup).set(\aziDeg,  -90);

~srcNode_0process.at(\nodeGroup).set(\t_trig, 1);
~srcNode_1process.at(\nodeGroup).set(\t_trig, 1);




~allSourceNodes[\srcNode_0].at(\process) == ~allSourceNodes[\srcNode_1].at(\process);

~scbr.satieGroupInstances[~myGroupName.asSymbol][~cloneName.asSymbol].set(\note, [89,1,1]);   // broken

// should be

~scbr.satieGroupInstances[~myGroupName.asSymbol][~cloneName.asSymbol].set(\note, [89,1,1]);     // new style



~scbr.satieGroupInstances[~myGroupName.asSymbol][~cloneName.asSymbol].set(\t_trig, 1);



~scbr.satieGroups.keysDo{ |key |
	var nodeSym = key;

	if (key != \default,
		{
			~scbr.killSatieGroup(key);
	});
};


~scbr.satieGroups


( { arg key;

	key.postln;

	~scbr.killSatieGroup(nil);

});





~myProcess.at(\nodeGroupProxy).group.set(\note, [85,0.5,0.5]);
~myProcess.at(\nodeGroupProxy).group.set(\t_trig, 1);
~myProcess.at(\nodeGroupProxy).group.set(\randTrigMaxMs, 0);

~myProcess.at(\nodeGroupProxy).group.set(\t_trig, 1);
~myProcess.at(\nodeGroupProxy).group.set(\aziDeg, -90);

~allSourceNodes[~nodeName].at(\proxy);



~connectionProcessCallback.value( ["/spatosc/core/connection/"++ ~connectionName++"/update", 0,0,-3,1,12345]);

~sourceProcessCallback.value( ["/spatosc/core/source/"++ ~nodeName ++"/event", \trigger, 1]);

// this is the way to access the process's params
~sourceProcessCallback.value( ["/spatosc/core/source/"++ ~nodeName ++"/event", \setParam, \gainDB, -40]);


// adjust group
~myProcess.at(\nodeGroupProxy).group.set(\gainDB, -30);
~myProcess.at(\nodeGroupProxy).group.set(\gainDB, -20);
~myProcess.dump;






//~nodeName="shitfuck";

~myProcess.at(\cloneCount).do( { arg item;
	var nodeName=(~nodeName++"_"++item).asSymbol;
	var groupName = ~myProcess.at(\nodeGroupName);
	var synth;
	synth = ~scbr.satieGroups[ groupName ][nodeName];
	synth.set(\gainDB, -10);
	synth.set(\t_trig, 1);
});







	10.do( { arg item;
			var nodename=(~nodeName++"_"++item).asSymbol;
	var synth;
	{
			synth = ~scbr.makeInstance(nodename.asSymbol, \default, ~myGroupName);
		     s.sync;
			synth.set(\gainDB, -3);
	}.fork
			//synth.at(\gainDB).postln;
			//self.gainDB.postln;

		});



	20.do( { arg item;
			var nodename=(~nodeName++"_"++item).asSymbol;
	var synth;
	{
		nodename.asSymbol.postln;
			synth = ~scbr.cleanInstance(nodename.asSymbol, ~myGroupName);
		     s.sync;
			synth.set(\gainDB, -3);
	}.fork
			//synth.at(\gainDB).postln;
			//self.gainDB.postln;

		});



{
        SynthDef(.....).add;
        s.sync;
        Synth(\newSDef, ...);
}.fork;





~synthName=~nodeName++"_12";

~scbr.satieGroups[~myGroupName][~synthName.asSymbol ].set(\gainDB, -30);

~synth  = ~scbr.satieGroups[~myGroupName][~synthName.asSymbol ];

~synth.set(\gainDB, -90);


~synth = ~scbr.makeInstance(~nodeName.asSymbol ,  \default, ~myGroupName);
~synth.dump

~synth.set(\gainDB, ~myProcess.at(\gainDB))


~myProcess.at(\gainDB);
~myProcess.at(\triggerIntervalMs)


~connectionCallback.value( ["/spatosc/core/connection/"++ ~connectionName++"/update", 0,0,-30,1,13456]);

~connectionCallback.value( ["/spatosc/core/connection/"++ ~connectionName++"/submerse", 1]);
~setEvent.value(~nodeName, \t_trig, 1);

~connectionCallback.value( ["/spatosc/core/connection/"++ ~connectionName++"/submerse", 0]);
~setEvent.value(~nodeName, \t_trig, 1);


~setEvent.value(~nodeName, \note, [80,1,1]);
~setEvent.value(~nodeName, \t_trig, 1);


~setEvent.value(~nodeName, \t_trig, 1);
~setEvent.value(~nodeName, \hpHz, 0);
~setEvent.value(~nodeName, \gainDB, 6);


~allSourceNodes[\bell_0].at(\proxy).set(\hpHz ,  10000 );
~setEvent.value(~nodeName, \t_trig, 1)


~allSourceNodes[\bell_0].at(\proxy).set(\hpHz ,   );




~scbr.satieGroups[\default].group.set(\hpHz ,  800 );

~scbr.satieGroups[\default].group.set(\hpHz ,  1 );

~scbr.satieGroups[\default].group.set(\t_trig, 1)

~scbr.satieGroups[\default].group.set(\decayscale, 0.6)


~setEvent.value(~nodeName, \t_trig, 1)



~allSourceNodes[\bell_0].at(\proxy).set(\gainDB ,  0 );




~scbr.satieGroups[\effect].set(\aux, 0);

~scbr.satieGroups[\default].set(\t_trig, 1);


~scbr.satieGroups[\default].group.set(\gainDB, 4);

~scbr.satieGroups[\default].set(\gainDB, -200);

~scbr.satieGroupInstances[\effect][\resonance_SC].set(\outputDB, -30);


~effectProx[\effect]



~allSourceNodes[\resonance_SC].at(\auxBus);

~allSourceNodes[\resonance_SC].at(\aux);


~allSourceNodes[\resonance_SC].put(\aux, 0);

~allSourceNodes[\resonance_SC].at(\auxbus);

~allSourceNodes[\resonance_SC].at(\proxy).set(\in, ~allSourceNodes[\resonance_SC].at(\auxBus));
~allSourceNodes[\resonance_SC].at(\proxy).set(\outputDB, -30);


 ~allSourceNodes[\srcNode_0]

ScIDE.open








gainDB




// proxyspace delay problem:

// 250 ms delay with this
~scbr.satieGroups[\default][~nodeName.asSymbol].set(\t_trig, 1);

// 0 ms delay with this
	~scbr.satieGroups[\default].group.set(\t_trig, 1);


~scbr.satieGroups[\default][~nodeName.asSymbol].set(\t_trig, 1);
~scbr.satieGroups[\default].group.set(\t_trig, 1);



		~cleanInstance = { | self, name, group = \default |


	~scbr.satieGroupInstances[\default][name].release();
			// fadeTime must be higher than SATIE internal fadeTime:
			~scbr.satieGroupInstances[group][name].clear(0.03);
			~scbr.satieGroupInstances[group].removeAt(name);
			nil;
		};









~allNodes.size;
~allNodes.clear;

~allNodes;

~dumpNodes.value();


~clearScene.value();


~createSource.value(\testNode0);
~setUri.value(\testNode0, "plugin://pink");



~deleteSource.value(\testNode2);


~clearNode.value(\testNode0);

~clearScene.value();


~setUri.value(\testNode0, "plugin://zkarpluck1");
~setUri.value(\testNode0, "plugin://pink");


~group.set(\t_trig, 1);



~setState.value(\testNode0, 1);



~allNodes[\testNode0];

~allNodes.removeAt(\testNode0);


~cleaninstance.value(\testNode0, ~prox);

~clearNode.value(\testNode0);
~dumpNodes.value();




~clearScene.value();


~nodeCount=3;


// "ball_142:spatOSCsource_143"


~connectionName = ~reverbName++"->listener:spatOSClistener_0";
~connectionCallback.value( ["/spatosc/core/connection/"++ "ball_0:spatOSCsource_1->listener:spatOSClistener_0" ++"/update", 45,0,-30,1,14000]);


~sourceCallback.value( ["/spatosc/core/source/"++~reverbName++"/prop", "outputDB", -30] );

 ["/spatosc/core/connection/"++ "ball_1:spatOSCsource_21->listener:spatOSClistener_0" ++"/update", 45,0,-30,1,14000].postln


~nodeCount=10;

// CREATE SOURCES

~nodeCount.do({ arg item;
	var nodename=("ball_"++item).asSymbol;
	var connectionName = nodename++ "->listener";
	postln("creating: "++nodename++" and connection:  "++ connectionName);
	~createSource.value(nodename, "plugin://zkarpluck1", \default);
	~createConnection.value(nodename, "listener");
	 // ~setUri.value(nodename, "plugin://zkarpluck1");
	//~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName ++"/spread", 5]);
	//~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName++"/update", 45,0,-80,1,14000]);

});
~allSourceNodes.size;



// SET CONNECTION

~nodeCount.do({ arg item;
	var nodename=("ball_"++item).asSymbol;
	var connectionName = nodename++"->listener";
	//postf("creating: "++nodename++"\n");
	 //~setUri.value(nodename, "plugin://zkarpluck1");
	~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName ++"/spread", 5]);
	~connectionCallback.value( ["/spatosc/core/connection/"++ connectionName++"/update", 45,0,-10,1,14000]);

});





// DELETE INSTANCE
~nodeCount.do({ arg item;
		var nodename=("ball_"++item).asSymbol;

	~deleteSource.value( nodename );
});


~incidenceVal = 0;

~incidenceIndex=0;
t = Task({ {
	~nodeCount.do( { arg item;
		var pitch = 55 + rand(10);
		var nodename=("ball_"++item).asSymbol;
		var connectionName = nodename++"->listener";
		// var incidence =  ~incidenceIndex.mod(100) * 0.01;

		// var pitch = 55 + rand(10);

		~incidenceIndex = (~incidenceIndex + 1) ;


		//incidence.postln;

		~setEvent.value(nodename, \note, [pitch,1,~incidenceVal]);
		~setEvent.value(nodename, \t_trig, 1);
		item.postln;
		0.2.wait;
	});
	//~globalSet.value(\t_trig, 1);
	0.wait; }.loop });

t.start;
t.stop;



~allSourceNodes.size;
~allSourceNodes.dump;


//mix=1.0, room=0.5, damp=0.5

//~setUri.value(~reverbName.asSymbol, "plugin://busreverb");



~setProperty.value(~reverbName, \in, ~scbr.aux[0]);
~setProperty.value(~reverbName, \outputDB, 10);
~setProperty.value(~reverbName, \mix, 1);  //wet only
~setProperty.value(~reverbName, \room, 0.8);
~setProperty.value(~reverbName, \damp, 0.1);
~setProperty.value(~reverbName, \aziDeg, -180);
~setProperty.value(~reverbName, \gainDB, -0);


	~globalSet.value(\gainDB, -80);




~globalSet.value(\fb, 0);
~globalSet.value(\pos, 0.5);





















~globalSet.value(\gain, 3);

~globalSet.value(\t_trig, 1);

~globalSet.value(\spread, 10);

~globalSet.set(\gainDB, -40);



	200.do( { arg item;
	var pitch = 55 + rand(50);
	var nodename=("testNode"++item).asSymbol;
	~setEvent.value(nodename, \note, [pitch,1,1]);
});








~sourceCallback.value( ["/spatosc/core/source/"++ "testNode0" ++"/event", \t_trig, 1]);

~sourceCallback.value( ["/spatosc/core/source/"++ "ball_17:spatOSCsource_18" ++"/event", \t_trig, 1]);
~sourceCallback.value( ["/spatosc/core/source/"++ "ball_17:spatOSCsource_18" ++"/event", \note, 70,1,1]);

~sourceCallback.value( ["/spatosc/core/source/"++ "ball_18:spatOSCsource_19" ++"/event", \note, 90,1,1]);
~sourceCallback.value( ["/spatosc/core/source/"++ "ball_18:spatOSCsource_19" ++"/event", \t_trig, 1]);


~createConnection.value(\testNode0, "ear");
~connectionCallback.value( ["/spatosc/core/connection/"++ "testNode0->ear" ++"/spread", 10]);
~connectionCallback.value( ["/spatosc/core/connection/"++ "testNode0->ear" ++"/update", 90,0,-0,1,14000]);

~globalParGroup.freeAll;


	~globalSet.value(\gainDB, -10);
	~globalSet.value(\c3, 2);

~globalSetState.value(0);


	~dumpNodes.value();

	~allNodes.size;

	~clearScene.value();


0.001.degrad


		~allNodes.keysDo { |key |
			var nodeSym = key;
			//postf("node: %  \n", key);
			~allNodes[nodeSym].keysDo { | key |
			if ( key == \connectionState,
				{
					postf(" %:   %  =  % \n",nodeSym,  key, ~allNodes[nodeSym].at(key));
			});
			};
		};



 SynthDef(\test, { arg freq = 440, amp = 1;
	//var freqLag = Lag.kr(freq, 10);
	Out.ar(0, SinOsc.ar(freq.lag(3), 0, amp));
 }).add;



>
a = Synth(\test);
a.set(\freq, 440, \amp, 0.8);

a.set(\freq, 440);
a.set(\freq, 240);





Server.default = s = Server.internal;
// 2D
a = VBAPSpeakerArray.new(2, [-60, 60, 0]); // 8 channel ring

a.speakers[1].dump;

b = a.loadToBuffer;

(
x = { |azi = 0, ele = 0, spr = 0|
VBAP.ar(2, PinkNoise.ar(0.2), b.bufnum, azi, ele, spr);
}.scope;
)



o = OSCresponderNode(s.addr, '/tr', { |time, resp, msg| msg.postln }).add;


o.remove;  // when done, you need to clean up the OSCresponderNode



w=Window.new("voicing", Rect(30, 30, 400, 140)).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=8@2;


l = EZSlider(w, 380@20, "azi", ControlSpec(-360, 360, \lin, 1, 0));
l.action_({ |ez| (  v.set(\aziDeg, (ez.value)))});

j = EZSlider(w, 380@20, "spread", ControlSpec(0, 100, \lin, 1, 0));
j.action_({ |ez| (  v.set(\spread, (ez.value)))});




// spread  units  (0 == directional, ....,  100 == omni)
(
v = {|in = 0, aziDeg = 0, eleDeg = 0, gainDB = 0, delayMs = 1, lpHz = 15000, spread = 10 |
	var gain= gainDB.dbamp;   // convert gainDB to gainAMP
	var delay = delayMs * 0.001;    // convert to seconds
	var slewDelay = 0.3; //  note: this needs to be improved ... smoother
	var slewGain = 0.03;
	var slewLp = 0.3;

	var insig;
	var aziScale = 0.01 * (100 - spread);


	var theta = aziScale * aziDeg *  0.01745329251994;  // radians

	var index = SinOsc.kr(0, theta);


	insig = LPF.ar(DelayC.ar(
		gain.lag(slewGain) *  PinkNoise.ar(0.2),
		maxdelaytime: 0.5,
		delaytime: delay.lag(slewDelay)), lpHz.lag(slewLp));

		//SendTrig.kr(Impulse.kr(4), 0, index);

	   Out.ar(0,Pan2.ar( insig, index ));
//}
}.scope;
)


(
v = {|in = 0, aziDeg = 0, eleDeg = 0, gainDB = 0, delayMs = 1, lpHz = 15000, spread = 1 |
PinkNoise.ar(0.2) * Math.
}.scope;
)




// test them out
{[45, 90, 135, 180, -135, -90, -45, 0].do({|ang| v.set(\azi, ang); 1.wait; }) }.fork;

// try the spread
x.set(\spr, .4);
x.set(\spr, 100); // all speakers


v.set(\azi,1); // all speakers


x.free; b.free;


// test them out
{[0, 45, 90, 135, 180, -135, -90, -45, 0].do({|ang| v.set(\aziDeg, ang); 1.wait; }) }.fork;

// try the spread
x.set(\spr, 1);
x.set(\spr, 100); // all speakers


x.set(\azi,-90); // all speakers


x.free; b.free;

~uriPath= "process://sheefa  cloneCount 20";
~stringArray = ~uriPath.asString.split($ );
~charIndex = ~stringArray[0].asString.find("://");
~processName = ~stringArray[0].asString.subStr(~charIndex+3);
~thisargsString = ~uriPath.asString.subStr(~stringArray[0].size+1);

~thisargsString.postln;
~argsString.postln;


~uriPath= "process://sheefa 444 shit arg2 2.2 arg3";




// ~argvec = ~valueString.split($ );
//
// ~argvec.size;
//
// if ( ~argvec.size >= 2,
// 	{
// 		if ( ~argvec[0].asString == "cloneCount",
// 			{
// 				'yes'.postln;
// 				~argvec[1].asFloat.postln;
//
// 			},
// 			// else bad arg
// 			{
// 				error("sheefa.setup: unrecognized key, expecting 'cloneCount' ");
// 		});
//
//
// 		~argvec[1].asFloat.postln;
// });
//
//
// ~argvec[1].asInt.clip(1, 10000);


//type = ~uriPath.asString.subStr(0, ~charIndex-1);




// ~stringArray[0].asString.find("://");
//
// ~temp.asString.find(" ");
//
//
// ~charIndex = ~uriPath.asString.find(~processName);
//
//
// ~temp = ~uriPath.asString.subStr(~charIndex);
//





