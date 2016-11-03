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

/* debugging
OSCFunc.trace(true);    // show OSC RX
OSCFunc.trace(false);

z = OSCresponderNode(s.addr, '/tr', { |time, resp, msg| msg.postln }).add;

z.remove;  // when done, you need to clean up the OSCresponderNode

SendTrig.kr(Impulse.kr(1), 0, freq);  //  in synthdef
*/
// uses a delay of two blocks to avoid transient mangulation by supernova


// args:   \note, #[ midiPitch60 == no transposition,    force: between -1 and 1,   incidence:  not used  ]
//   when force == 0,  NOTE OFF


// set up VBAP
~tmpSpkConfig = VBAPSpeakerArray.new(2, [-90, 0, 90]); // 3 channel ring   using 180 degree range (-90 to 90 )
~tmpVbuf= ~tmpSpkConfig.loadToBuffer;


~name = "3chLooper".asSymbol;

// note:  bufnum must be first arg !!

// sampSpr:  0 narrow -----   100  wide
//  3 channel mapping   [ low, med, high ] :   -90, 0, 90  respectively
// eLamp, eMamp,eHamp are amp scalers for the respective channels
// exp acts on amp of low and high channels
// initializes to note-on playing state

// sampAZI clipped from -90 to 90

~function = { | bufnum=0, glide=0.2, loopRel=0, startPosSecs=0, trimDB=0, startLoop=0, endLoop=99999999, ipol=2, curve=0, attackMs=0.01, releaseSecs=1, warp=5, transp=0, sampAzi=0, sampSpr=0,  exp=1, eLamp=1, eMamp=1, eHamp=1, boostDB=3, boostExp = 1, note = #[60, 1, 1] |


	var env, sig;
	var noteFq = (transp + note[0]).midicps;   // using midi 60 == speed of 1,  midi 48 == speed of
	var gate = abs (note[1]);
	var incidence = abs (note[2]);   // apprently this does not work
	var rate =  noteFq/261.6255653006;
	var attackSecs = attackMs * 0.001;
	var startPos = startPosSecs * SampleRate.ir;
	var blockDelaySecs = ControlDur.ir * 2;  // delay time used to avoid transient mangulation by supernova
	var mixScalers,mixdown,vbapScalers;
	var amp, boostIndex;


	var eScalers = [1,1,1];

	boostIndex = sampAzi.clip(-90, 90) * 0.011111111;  // normalize range

	boostIndex = abs ( boostIndex ) ** boostExp;

	amp = 1 + boostIndex * boostDB.dbamp;

	// incidence = incidence.clip(0,1);    // incidence not used


	rate = VarLag.kr(rate, glide, curve, warp);  // was Lag.kr(rate, glide);

	env = EnvGen.ar(Env.adsr(attackSecs, 0,1,releaseSecs), gate, doneAction: 0 );  // no kill,  was doneAction: 2 == kill


	sig = LoopBuf.ar(3,bufnum, BufRateScale.kr(bufnum) * rate, gate+loopRel, startPos, startLoop, endLoop, ipol);

	vbapScalers = VBAP.kr(~tmpSpkConfig.numSpeakers, 1.0, ~tmpVbuf.bufnum, sampAzi, 0, sampSpr);


	eScalers[0] = eLamp * (vbapScalers[0] ** exp);
	eScalers[1] = eMamp * vbapScalers[1];
	eScalers[2] = eHamp * (vbapScalers[2] ** exp);

	mixdown =  Mix.ar(eScalers * sig);


	mixdown = trimDB.dbamp * env *  amp * DelayN.ar(mixdown, ControlDur.ir*10, blockDelaySecs);  // offset output by  N blocks to avoid transient mangulation by supernova

	// Out.ar(0, mixdown);   // for debugging

};


/*



b = Buffer.read(s,"/Users/zack/src/aquakhoria/AquaKhoria_UnityProject/Assets/StreamingAssets/sound/3chBellyA.wav");

SynthDef(\sheefa, ~function ).add;

(
x = Synth.new( \sheefa ); // create the synth

x.set(\bufnum, b.bufnum, \glide, 1, \startLoop, 0, \endLoop, 999999, \releaseSecs, 0.5,  \note, #[60, 1, 1]);

)

x.set(\curve, 6, \attackMs, 400, \warp, 5, \transp, 0, \glide, 0, \releaseSecs, 0.5,  \startPosSecs, 0.9, \note, #[60, 1, 1] );
x.set(\note, #[60, 0, 1]);


x.set(\sampAzi, 90);
x.set(\sampAzi, 45);
x.set(\sampAzi, 0);
x.set(\sampAzi, -45);
x.set(\sampAzi, -90);

x.set(\sampSpr, 0);
x.set(\sampSpr, 50);


x.set(\exp,  3);


x.set(\eHamp, 1);
x.set(\eMamp, 0.3);
x.set(\eLamp, 1);






x.set(\glide, 0, \note, #[60, 1, 1] );

x.set(\glide, 0, \transp, -12);

x.set(\curve, 6, \warp, 5, \glide, 30, \note, #[120, 1, 1] );

x.set(\releaseSecs, 2, \note, #[66, 0, 1]);   // note off

x.set(\note, #[60, 0, 1]);
x.set(\startPosSecs, 30.rand, \note, #[60, 1, 1]);


x.free;


// open up GUIs for monitoring
if (~plotTree == nil,  { ~plotTree=s.plotTree;});
if (~makeGui == nil,  { ~plotTree=s.makeGui;});
if (~meter == nil,  { ~plotTree=s.meter;});

*/




