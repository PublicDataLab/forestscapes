// Engine_Forestscapes2

// Inherit methods from CroneEngine
Engine_Forestscapes2 : CroneEngine {

    // Forestscapes2 specific v0.1.0
	var server;
	var bufs;
	var buses;
	var syns;
	var oscs;
    // Forestscapes2 ^

    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }

	loadTape {
		arg tape=1,filename="";
		var tapeid="tape"++tape;
		if (filename=="",{
			("[forestscapes2] error: need to provide filename").postln;
			^nil
		});
		bufs.put(tapeid,Buffer.read(server,filename,action:{ arg buf;
			("[forestscapes2] loaded"+tape+filename).postln;
			syns.keysValuesDo({ arg k, syn;
				if (syn.isRunning,{
					("[forestscapes2] updating"+syn).postln;
					syn.set(\buf,buf);
				});
			});
		}));
	}

	playTape {
		arg tape=1,player=1,rate=1.0,db=0.0,timescale=1;
		var amp=db.dbamp;
		var tapeid="tape"++tape;
		var playid="player"++player++tapeid;

		if (bufs.at(tapeid).isNil,{
			("[forestscapes2] cannot play empty tape"+tape).postln;
			^0
		});
		("[forestscapes2] player"+player+"playing tape"+tape).postln;

		syns.put(playid,Synth.head(server,"looper",[\tape,tape,\player,player,\buf,bufs.at(tapeid),\baseRate,rate,\amp,amp,\timescale,timescale]).onFree({
			("[forestscapes2] player"+player+"finished.").postln;
		}));
		NodeWatcher.register(syns.at(playid));
	}


    alloc {
        // Forestscapes2 specific v0.0.1
        var server = context.server;

		bufs = Dictionary.new();
		syns = Dictionary.new();
		oscs = Dictionary.new();
		buses = Dictionary.new();

		SynthDef("looper",{
			// main arguments
			arg buf,tape,player,baseRate=1.0,amp=1.0,timescale=0.2;
			// variables to store UGens later
			var volume;
			var switch=0,snd,snd1,snd2,pos,pos1,pos2,posStart,posEnd,index;
			// store the number of frames and the duraiton
			var frames=BufFrames.kr(buf);
			var duration=BufDur.kr(buf);
			// LFO for the start point <-- tinker
			var lfoStart=SinOsc.kr(timescale/Rand(30,60),Rand(hi:2*pi)).range(1024,frames-10240);
			// LFO for the window lenth <-- tinker
			var lfoWindow=SinOsc.kr(timescale/Rand(60,120),Rand(hi:2*pi)).range(4096,frames/2);
			// LFO for the rate (right now its not an LFO)
			var lfoRate=baseRate;//*Select.kr(SinOsc.kr(1/Rand(10,30)).range(0,4.9),[1,0.25,0.5,1,2]);
			// LFO for switching between forward and reverse <-- tinker
			var lfoForward=Demand.kr(Impulse.kr(timescale/Rand(5,15)),0,Drand([0,1],inf));
			// LFO for the volume <-- tinker
			var lfoAmp=SinOsc.kr(timescale/Rand(10,30),Rand(hi:2*pi)).range(0.25,0.5);
			// LFO for the panning <-- tinker
			var lfoPan=SinOsc.kr(timescale/Rand(10,30),Rand(hi:2*pi)).range(-1,1);

			// calculate the final rate
			var rate=Lag.kr(lfoRate*(2*lfoForward-1),1)*BufRateScale.kr(buf);

			// modulate the start/stop
			posStart = lfoStart;
			posEnd = Clip.kr(posStart + lfoWindow,0,frames-1024);

			// posStart = Clip.kr(\start_pos.kr(0)*frames,1024,frames-10240);
			// posEnd = Clip.kr(posStart + (\window.kr(0.1)*frames),0,frames-1024);

			// LocalIn collects the a trigger whenever the playhead leaves the window
			switch=ToggleFF.kr(LocalIn.kr(1));

			// playhead 1 has a play position and buffer reader
			pos1=Phasor.ar(trig:1-switch,rate:rate,end:frames,resetPos:((lfoForward>0)*posStart)+((lfoForward<1)*posEnd));
			snd1=BufRd.ar(2,buf,pos1,1.0,4);

			// playhead 2 has a play position and buffer reader
			pos2=Phasor.ar(trig:switch,  rate:rate,end:frames,resetPos:((lfoForward>0)*posStart)+((lfoForward<1)*posEnd));
			snd2=BufRd.ar(2,buf,pos2,1.0,4);

			// current position changes according to the swtich
			pos=Select.ar(switch,[pos1,pos2]);

			// send out a trigger anytime the position is outside the window
			LocalOut.kr(
				Changed.kr(Stepper.kr(Impulse.kr(20),max:1000000000,
					step:(pos>posEnd)+(pos<posStart)
				))
			);

			// crossfade bewteen the two sounds over 50 milliseconds
			snd=SelectX.ar(Lag.kr(switch,0.05),[snd1,snd2]);

			// apply the volume lfo
			volume = amp*lfoAmp*EnvGen.ar(Env.new([0,1],[Rand(1,10)],4));

			// send data to the GUI
			SendReply.kr(Impulse.kr(10),"/position",[tape,player,posStart/frames,posEnd/frames,pos/frames,volume,(lfoPan+1)/2]);

			// do the panning
			snd=Balance2.ar(snd[0],snd[1],lfoPan);

			// final output
			Out.ar(0,snd*volume/5);
		}).add;


		// effects
		SynthDef("effects",{
			arg amp=1.0;
			var snd=In.ar(0,2);
			snd=HPF.ar(snd,80);
			
			// add some reverb
			snd=SelectX.ar(LFNoise2.kr(1/3).range(0.3,0.6),[
				snd,
				FreeVerb2.ar(snd[0],snd[1])
			]);

			// replace the output with the effected output
			ReplaceOut.ar(0,snd*Lag.kr(amp));
		}).add;


		server.sync;


		syns.put("fx",Synth.tail(server,"effects"));
		"done loading.".postln;

		oscs.put("position",OSCFunc({ |msg|
			var oscRoute=msg[0];
			var synNum=msg[1];
			var dunno=msg[2];
			var tape=msg[3].asInteger;
			var player=msg[4].asInteger;
			var posStart=msg[5];
			var posEnd=msg[6];
			var pos=msg[7];
			var volume=msg[8];
			var pan=msg[9];
			NetAddr("127.0.0.1", 10111).sendMsg("position",player,pos);
			NetAddr("127.0.0.1", 10111).sendMsg("posStart",player,posStart);
			NetAddr("127.0.0.1", 10111).sendMsg("posEnd",player,posEnd);
			NetAddr("127.0.0.1", 10111).sendMsg("volume",player,volume);
			NetAddr("127.0.0.1", 10111).sendMsg("pan",player,pan);
		}, '/position'));

        this.addCommand("load_tape","is",{ arg msg;
        	this.loadTape(msg[1],msg[2]);
        });

        this.addCommand("play_tape","iifff",{ arg msg;
        	this.playTape(msg[1],msg[2],msg[3],msg[4],msg[5]);
        });
    }


	free {
		bufs.keysValuesDo({ arg k, val;
			val.free;
		});
		syns.keysValuesDo({ arg k, val;
			val.free;
		});
		buses.keysValuesDo({ arg k, val;
			buses.free;
		});
		oscs.keysValuesDo({ arg k, val;
			oscs.free;
		});
	}
}
