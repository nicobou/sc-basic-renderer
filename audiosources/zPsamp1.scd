// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



// Play a sample buffer

// uses a delay of two blocks to avoid transient mangulation by supernova


// args:   midiPitch60 == no transposition,  force & incidence  between -1 and 1


~name = \zPsamp1;
~function = { | bufnum = 0, loop = 0, startPos=0, t_trig=0, trimDB=0,  note = #[60, 1, 0.7]  |

	var freq = note[0].midicps;
	var amp = abs (note[1]);
	var incidence = abs (note[2]);   // apprently this does not work
	var rate =  freq/261.6255653006;
	var lpassFq,hpassFq;
	var ampScaled;
	var sig;
    var i_blockDelay = 2;  // block count, chosen by ear
	
    var blockDelaySecs = ControlDur.ir * i_blockDelay;

	incidence = incidence.clip(0,1);
	amp = amp.clip(-1,1);
	ampScaled = abs(amp) **(0.7);

	lpassFq = 100 + (incidence**(0.7) * 21900) ;  // used to cut highs when incidence is low

	hpassFq = 800 - ( ampScaled * 799) ;  // used to pass lows when force is high

	sig = trimDB.dbamp * PlayBuf.ar(1, bufnum, rate, t_trig, startPos, loop);


	sig = BLowPass.ar(  (ampScaled * sig),  Lag.kr(lpassFq, 0.01) , 5);

    sig = BHiPass.ar( sig ,  Lag.kr(hpassFq, 0.01) , 5);

	DelayN.ar(sig, ControlDur.ir*10, blockDelaySecs);   // offset output by  N blocks to avoid transient mangulation by supernova
};



/*  TEST
SynthDef(~name, ~function ).add;



~v1 =Synth.new(~name,  [ \i_doneAction, 0, \randTrigMaxMs , 500, \durMs, 100, \attackBend, 3 , \attackMS, 10]);

~v1 =Synth.new(~name);
~v1.set(\t_trig, 1);


*/




