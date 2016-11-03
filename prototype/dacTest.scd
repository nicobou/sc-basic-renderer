// evaulate this and look for GUI for dac testing
// z.s

//    to stop without gui
//		~task.stop;
//		~dacTestSyn.release;



SynthDef(\speakerMapTest, { |out, gate=1|
    // doneAction: 2 frees the synth when EnvGen is done
    Out.ar(out, WhiteNoise.ar(1) * EnvGen.kr(Env.asr(0.03, 0.3, 0.01), gate, doneAction:2));
}).store; // use store for compatibility with pattern example below

//~dacTestSyn = Synth(\speakerMapTest, [\out, 0,]); // play out through hardware output bus 0 (see Out.help)
//~dacTestSyn.release; // releases and frees the synth (if doneAction is > 2; see EnvGen)


~channelCount=2;

~task= Task({
    loop {
		~channelCount .do({ arg item;
~dacTestSyn = Synth(\speakerMapTest, [\out, item,]); // play out through hardware output bus 0 (see Out.help)

      // item.postln;
            0.33.wait;
~dacTestSyn.release;
        });
    }
});


~dacTestWindow=Window.new("dac testing", Rect(30, 30, 400, 60)).front;
~dacTestWindow.view.decorator=FlowLayout(~dacTestWindow.view.bounds);
~dacTestWindow.view.decorator.gap=8@2;


~stateButton = Button(~dacTestWindow, 75 @ 20);
~stateButton.states = [
    ["Start", Color.black, Color.green(0.7)],
    ["Stop", Color.white, Color.red(0.7)]
];

~stateButton.action = { |view|
	view.value.postln;

	if (view.value == 1, {
		~task.play;
	},
	//else stop
	{
		~task.stop;
		~dacTestSyn.release;
	});

};

~chanCountSlider = EZSlider(~dacTestWindow, 380@20, "channels", ControlSpec(0, 31, \lin, 1, 2));
~chanCountSlider.action_({ |ez| (  ~channelCount = ez.value;   )});



