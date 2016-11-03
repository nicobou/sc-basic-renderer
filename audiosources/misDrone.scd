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

/*(
SynthDef(\sins, {
    | freq = 200, dur = 22, amp = 0.75|
    var bnq = Array.with(
        1-SinOsc.ar(freq, mul: 0.7),
        1-SinOsc.ar((freq * 4) * 1.0533610359546 * (SinOsc.kr(0.01, mul: 0.01)+ 1), mul: 0.6),
        1-SinOsc.ar((freq * 5)  * 1.2541124095491 * (SinOsc.kr(0.01, mul:  0.01) + 1), mul: 0.5),
        1-SinOsc.ar((freq * 6) * 1.8768759933376 *(SinOsc.kr(0.01)-1), mul: 0.02);
    );
    var att, sustain, amplitude, mix, env, envGen, resonance, verb;
    att = dur*0.2;
    sustain = dur;
    amplitude = amp;
    mix = bnq[0] + bnq[1] + bnq[2] + bnq[3] * 0.01;
    env = Env.linen(att, sustain, dur, amplitude, \cub);
    envGen = EnvGen.kr(env, 1, doneAction: 2);
    resonance = Klank.ar(`[
        [(freq*0.001) * 521, (freq*0.001) * 732, (freq*0.001) * 934],  // freqs
		[0.7, 0.45, 0.25],// amps
		[0.8, 0.8, 0.8]   // ring times
		],
        mix);
        verb = FreeVerb.ar(resonance, 0.7, 1, 0.5, Line.kr(0, 0.6, 0.5, mul: 0.7));
    (LeakDC.ar(Out.ar(0,(verb*envGen)!2)));
}).add;
)*/


~name = \misDrone;
~function = { | freq = 200, dur = 22, amp = 0.75|
	var bnq = Array.with(
		1-SinOsc.ar(freq, mul: 0.7),
		1-SinOsc.ar((freq * 4) * 1.0533610359546 * (SinOsc.kr(0.01, mul: 0.01)+ 1), mul: 0.6),
		1-SinOsc.ar((freq * 5)  * 1.2541124095491 * (SinOsc.kr(0.01, mul:  0.01) + 1), mul: 0.5),
		1-SinOsc.ar((freq * 6) * 1.8768759933376 *(SinOsc.kr(0.01)-1), mul: 0.02);
	);
	var att, sustain, amplitude, mix, env, envGen, resonance, verb;
	att = dur*0.2;
	sustain = dur;
	amplitude = amp;
	mix = bnq[0] + bnq[1] + bnq[2] + bnq[3] * 0.01;
	env = Env.linen(att, sustain, dur, amplitude, \cub);
	envGen = EnvGen.kr(env, 1, doneAction: 2);
	resonance = Klank.ar(`[
		[(freq*0.001) * 521, (freq*0.001) * 732, (freq*0.001) * 934],  // freqs
		[0.7, 0.45, 0.25],// amps
		[0.8, 0.8, 0.8]   // ring times
	],
	mix);
	verb = FreeVerb.ar(resonance, 0.7, 1, 0.5, Line.kr(0, 0.6, 0.5, mul: 0.7));
	(LeakDC.ar(verb*envGen)!2);
	verb;
};