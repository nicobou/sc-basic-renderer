/*

if (w != nil, {w.close});

w=Window.new("AQ_bell_Preset voicing", Rect(500, 30, 400, 140)).front;
w.view.decorator=FlowLayout(w.view.bounds);
w.view.decorator.gap=8@2;


// g = EZSlider(w, 380@20, "pitch ", ControlSpec(40, 110, \lin, 1, 60));
// g.action_({ |ez| (  ~bellSet.value(\note, [ ez.value, 1, 0.5 ] );  ~bellSet.value(\t_trig, 1);)});


// h = EZSlider(w, 380@20, "amp", ControlSpec(0, 1, \lin, 0.01, 0.5));
// h.action_({ |ez| (  ~globalSet.value(\amp, (ez.value)))});
//


// g = EZSlider(w, 380@20, "decay", ControlSpec(0.0, 1, \lin, 0.01, 0.14));
// g.action_({ |ez| (  ~preset_setParamAll.value(\decay, (ez.value)))});


j = EZSlider(w, 380@20, "c1", ControlSpec(0.05, 5, \lin, 0.01, 1));
j.action_({ |ez| (  ~preset_setParamAll.value(\c1, (ez.value)))});


k = EZSlider(w, 380@20, "c3", ControlSpec(0.05, 20, \lin, 0.01, 1));
k.action_({ |ez| (  ~preset_setParamAll.value(\c3, (ez.value)))});

l = EZSlider(w, 380@20, "fb", ControlSpec(0.0, 100, \lin, 0.1, 20));
l.action_({ |ez| (  ~preset_setParamAll.value(\fb, (ez.value)))});

m = EZSlider(w, 380@20, "PRESET", ControlSpec(0.0, 7, \lin, 1, 0));
m.action_({ |ez| (  ~setPreset.value( (ez.value)))});




// proxyspace delay problem:

// 250 ms delay with this
 //   ~scbr.satieGroups[\default][\ball_0].set(\t_trig, 1);

// 0 ms delay with this
//	~scbr.satieGroups[\default].group.set(\t_trig, 1);




OSCdef(\presetCallback ).clear.free;

OSCdef(\presetCallback, ~presetCallback, "/a.renderer/preset", recvPort: 18032);


/*~preset_sendAll.value(1,5, 100);

~preset_setParamAll.value(\c1, 9);

~preset_setParamAll.value(\c3, 2);

~preset_setParamAll.value(\fb, 7);*/




~preset_setParamAll = { arg pname, value  ;

	~particule1_instances.do{ |item |
		var groupName = item.nodeGroupName.asSymbol;
		~scbr.satieGroups[groupName].set(pname.asSymbol, value);
	};
	~particule2_instances.do{ |item |
		var groupName = item.nodeGroupName.asSymbol;
		~scbr.satieGroups[groupName].set(pname.asSymbol, value);
	};
};


~preset_sendAll = { arg c1 = 2, c3 = 1, fb = 0 ;

	~particule1_instances.do{ |item |
		var groupName = item.nodeGroupName.asSymbol;
		~scbr.satieGroups[groupName].set(\c1, c1,  \c3, c3, \fb,  fb);
	};
	~particule2_instances.do{ |item |
		var groupName = item.nodeGroupName.asSymbol;
		~scbr.satieGroups[groupName].set(\c1, c1,  \c3, c3, \fb,  fb);
	};
};




~setPreset = {
	arg presetNo;
	if (presetNo < 0, {presetNo=0});
	if (presetNo > 7, {presetNo=6});



	postf("~setPreset no: %\n", presetNo.asInt);
	switch (presetNo.asInt,
		0,
		{

						postf("~setPreset no: %\n", presetNo);

			// harp 0
			~preset_sendAll.value( 0.4, 5, 0);
		},
		1,
		{
			// harp 1
			~preset_sendAll.value( 0.38, 6.11, 0);
		},
		2,
		{
			// harp 2 (longer dur)
			~preset_sendAll.value( 0.15, 4.51, 0);
	/*		~ballSet.value(\c1, 0.15);
			~ballSet.value(\c3, 4.51);
			~ballSet.value(\fb, 0);
*/
		},
		3,
		{
			// harp 3 (feather)
			~preset_sendAll.value( 0.15, 9.51, 0);
		// ~ballSet.value(\c1, 0.15);
		// ~ballSet.value(\c3, 9.51);
		// ~ballSet.value(\fb, 0);


		},
		4,
		{
			// lantern zoner
			~preset_sendAll.value( 0.11, 3, 100);
/*			~ballSet.value(\c1, 0.11);
			~ballSet.value(\c3, 3);
			~ballSet.value(\fb, 100);*/

		},
		5,
		{
			// lantern zoner (shorter)
			~preset_sendAll.value( 0.7, 3, 100);
			// ~ballSet.value(\c1, 0.7);
			// ~ballSet.value(\c3, 3);
			// ~ballSet.value(\fb, 100);

		},
		6,
		{
			// Unused
			~preset_sendAll.value( 0.2, 6, 60);
		},
		7,
		{
			// Unused
			~preset_sendAll.value( 2.81, 20, 65);
		}
	);
};


~presetCallback = {
	arg msg;
	var presetNo = msg[1];

	postf("~basicRendererCallback: command: %, msg: %, \n", presetNo, msg);

	if (msg.size < 2,
		{
			"~presetCallback: empty message".warn;
			postf("~presetCallback MESS LEN: %", msg.size);

		},
		// else
		{
			~setPreset.value(presetNo);
	});
};



~setPreset.value(2);

//~scbr.satieGroups[\default].set(\decay, 0.0, \t_trig, 1)

*/ßßß
