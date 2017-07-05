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

SatieRenderer {
	var <satieConfig;

	var <groups, <groupInstances, generators, effects;


	*new {|satieConfig|
		^super.newCopyArgs(satieConfig).initRenderer;
	}

	initRenderer {
		groups = Dictionary.new();
		groupInstances = Dictionary.new();
		generators = IdentityDictionary.new();
		effects = IdentityDictionary.new();
		// TODO:
		// for some reason, we need to create the default group explicitly elsewhere, probably some timing or synchronicity
		// needs to be figured out.
		// satieConfig.server.doWhenBooted(this.makeSatieGroup(\default), onFailure: {"server did not boot".warning;});
		// this.makeSatieGroup(\default);
	}

	makeSynthDef {|
		id,
		srcName,
		srcPreToBusses,
		srcPostToBusses,
		spatSymbolArray,
		firstOutputIndexes = #[0],
		paramsMapper = \defaultMapper,
		synthArgs = #[]|

		var dico;
		if(satieConfig.audioPlugins.at(srcName) != nil,
			{
				dico = satieConfig.audioPlugins;
				generators.add(id.asSymbol -> srcName.asSymbol);
			},
			{
				dico = satieConfig.fxPlugins;
				effects.add(id.asSymbol -> srcName.asSymbol);
			}
		);

		"params mapper %".format(paramsMapper).postln;

		SatieFactory.makeSynthDef(
			id,
			dico.at(srcName).getSrc,
			srcPreToBusses,
			srcPostToBusses,
			spatSymbolArray.collect({|item, i|
				satieConfig.spatPlugins.at(item).getSrc
			}),
			firstOutputIndexes,
			satieConfig.mapperPlugins.at(paramsMapper).getSrc,
			synthArgs
		);
	}

	makeInstance {| name, synthDefName, group = \default, synthArgs = #[] |
		var synth = Synth(synthDefName, args: synthArgs, target: groups[group], addAction: \addToHead);
		groupInstances[group].put(name, synth);
		^synth;
	}

	makeKamikaze {| name, synthDefName, group = \default, synthArgs = #[] |
		var synth = Synth(synthDefName ++ "_kamikaze", args: synthArgs, target: groups[group], addAction: \addToHead);
		^synth;
	}

	makeSatieGroup { |  name, addAction = \addToHead |
		var group;
		"Creating group %".format(name).postln;
		group = ParGroup.new(addAction: addAction);
		groups.put(name.asSymbol, group);
		groupInstances.put(name.asSymbol, Dictionary.new);
		^group;
	}

	killSatieGroup { | name |
		groups[name].free;
		groupInstances[name].free;
		groups.removeAt(name);
		groupInstances.removeAt(name);
	}

	cleanInstance {|name, group = \default |
		groupInstances[group][name].free();
		groupInstances[group].removeAt(name);
	}

	pauseInstance {|name, group = \default |
		groupInstances[group][name].release();
	}
}