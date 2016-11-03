// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ~name = \sndFile;
// ~function = { | bufnum = 0, loop = 0, startPos=0, rate = 1, t_trig=0 |
// 	// DiskIn.ar(1, bufnum, loop = loop);
// 	PlayBuf.ar(1, bufnum, rate, t_trig, startPos, loop);
// };
//


// Play a sample buffer using global synchronization index

 ~name = \syncSamp1;


// args:   midiPitch60 == no transposition,  force & incidence  between -1 and 1
// pitch disabled




if ( ~syncBus == nil,
	{
		"\syncSamp1: setting up global Phasor".inform;
		~syncBus = Bus.audio(s,1); // this will be our sync bus
});


// set up needed sync signal generator and bus for this synthdef
SynthDef(\globalPhasor, {| t_trig = 0 |
	var invSR;
	invSR = (1 / SampleRate.ir);
	Out.ar(~syncBus, Phasor.ar(t_trig, invSR, 0,  36000   ));         // increments every second wraps around once every 36000 seconds==10 hours
}).add;



// set up VBAP
~tmpSpkConfig = VBAPSpeakerArray.new(2, [0, 60, 120, 180, -120, -60]); // 6 channel ring
~tmpVbuf= ~tmpSpkConfig.loadToBuffer;

/* NOTE: this generator must be instantiated for the audiosource defined in this file to work
copy the code below into the project file   ".main" to be evaluated
		if (~phasorSync == nil,
			{
		"creating phasorSync generator".inform;
			~phasorSync = Synth.before(s,\globalPhasor);
		});
*/
// spread == 0, narrow,  spread == 100  wide
~function ={| buf = 0, sampAzi = 0, sampSpr = 0, indexSecs = 0, t_trig = 0, loop = 1, durSecs = 4, fadeSecs = 2, trimDB=0,  note = #[60, 1, 1] |

	var mixdown;
	var mixScalers;
	var vbapMix;
	//var bufDur = BufFrames.kr(buf) /  BufSampleRate.kr(buf);
	//var framesPerSecond = BufFrames.kr(buf) / bufDur;

	var bufSR = BufSampleRate.ir(buf);
	var freq = note[0].midicps;   // not used
	var amp = abs (note[1]);
	var incidence = abs (note[2]);
	var lpassFq,hpassFq;
	var ampScaled;
	var interpolation = 4;  // 1 means no interpolation, 2 is linear, 4 is cubic interpolation.

	var phasor =  (In.ar(~syncBus, 1) + indexSecs);  // get the global phasor for sample reading index

	var wrappedPhasor =  Wrap.ar( phasor,0, BufDur.kr(buf) );   // phasor.Mod(buffDur)

	var outSig = BufRd.ar(6, buf, (wrappedPhasor * bufSR), loop, interpolation);

	var envShape = Env.new([0, 1, 1, 0], [0.01, durSecs, fadeSecs ],[0, 0, 0]);

	var envelope = EnvGen.ar(envShape, t_trig) ;

	incidence = incidence.clip(0,1);
	amp = amp.clip(-1,1);
	ampScaled = abs(amp) **(0.7);

	lpassFq = 100 + (incidence**(0.7) * 21900) ;  // used to cut highs when incidence is low

	// WAS hpassFq = 800 - ( ampScaled * 799) ;  // used to pass lows when force is high
	hpassFq = 800 - ( incidence * 799) ;  // used to pass lows when incidence is high

	mixScalers = VBAP.kr(~tmpSpkConfig.numSpeakers, 1.0, ~tmpVbuf.bufnum, sampAzi, 0, sampSpr);
	vbapMix = mixScalers * outSig;

	mixdown =  Mix.ar(vbapMix);

	mixdown = trimDB.dbamp * mixdown * envelope;

	mixdown = BLowPass.ar(  (ampScaled * mixdown),  Lag.kr(lpassFq, 0.02) , 5);

	mixdown = BHiPass.ar( mixdown ,  Lag.kr(hpassFq, 0.02) , 5);

	// enable for debugging
	//Out.ar([0,1],mixdown);
};


// DEBUG
/*
SynthDef(\testSyncSamp1, ~function).add;

// open up GUIs for monitoring
if (~plotTree == nil,  { ~plotTree=s.plotTree;});
if (~makeGui == nil,  { ~plotTree=s.makeGui;});
if (~meter == nil,  { ~plotTree=s.meter;});


b = Buffer.read(s, "/Users/zack/Dropbox/Unity3D/zkAuthoring/sound/Reaper/6ChanSoundfiles/iceCave6chAcc.wav");
b = Buffer.read(s, "/Users/zack/Dropbox/Unity3D/zkAuthoring/sound/Reaper/6ChanSoundfiles/6chTestLoop.wav");
b = Buffer.read(s, "/Users/zack/Dropbox/Unity3D/zkAuthoring/sound/Reaper/6ChanSoundfiles/6chSoundfileTest.wav");


~phasorSync.free;
~phasorSync = Synth.before(s,\globalPhasor);







x = Synth(\testSyncSamp1, [\buf, b, \note, #[60, 1, 1], \loop, 0, \indexSecs, 0,  \sampAzi, 360.rand, \durSecs, 300, \fadeSecs, 2, \t_trig, 1 ]);


~phasorSync.set(\t_trig, 1);
x.set(\t_trig, 1);



x.set(\sampAzi, -60);
x.set(\sampSpr, 100)
x.set(\startPosSecs, 0);
x.set(\durSecs, 333.8);
x.set(\loop, 1);
x.set(\t_trig, 1);

x.set(\sampAzi, 360.rand);

x.free;


*/











