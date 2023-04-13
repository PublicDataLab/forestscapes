-- forestscapes: fields
--
-- llllllll.co/t/forestscapes
--
-- pseudo-ambisonics of
-- field recordings.
--
--    ▼ instructions below ▼
--
-- K3/K2 adds/removes sound
-- E1 changes volume
-- E2 changes rate
-- E3 changes movement speed

PATH_TO_SAMPLES=_path.code.."forestscapes/sounds/field/"

tree_=include("lib/tree")
engine.name="Forestscapes1"
player={}

reverb_settings_saved={}
reverb_settings={
  reverb=2,
  rev_eng_input=0,
  rev_return_level=0,
  rev_low_time=9,
  rev_mid_time=6,
}
function init()
  --os.execute(_path.code.."forestscapes/lib/oscnotify/run.sh &")

  for k,v in pairs(reverb_settings) do
    reverb_settings_saved[k]=params:get(k)
    params:set(k,v)
  end

  print("starting")

  params:set("reverb",1)
  params:set("rev_eng_input",-6)
  params:set("rev_return_level",-6)
  params:set("rev_low_time",9)
  params:set("rev_mid_time",6)
  tree=tree_:new{x=120,y=64,age=math.random(70,100)/100}

  -- setup osc
  osc_fun={
    oscnotify=function(args)
      print("file edited ok!")
      rerun()
    end,
    lr=function(args)
      if player[tonumber(args[1])]==nil then
        player[tonumber(args[1])]={lr=0,fb=0,amp=0}
      end
      player[tonumber(args[1])].lr=tonumber(args[2])
    end,
    fb=function(args)
      if player[tonumber(args[1])]==nil then
        player[tonumber(args[1])]={lr=0,fb=0,amp=0}
      end
      player[tonumber(args[1])].fb=tonumber(args[2])
    end,
    on=function(args)
      if player[tonumber(args[1])]==nil then
        player[tonumber(args[1])]={lr=0,fb=0,amp=0}
      end
      print("on")
      tab.print(args)
      player[tonumber(args[1])].on=tonumber(args[2])==1
    end,
    amp=function(args)
      if player[tonumber(args[1])]==nil then
        player[tonumber(args[1])]={lr=0,fb=0,amp=0}
      end
      player[tonumber(args[1])].amp=tonumber(args[2])
    end,
  }
  osc.event=function(path,args,from)
    if string.sub(path,1,1)=="/" then
      path=string.sub(path,2)
    end
    if path~=nil and osc_fun[path]~=nil then
      osc_fun[path](args)
    else
      -- print("osc.event: '"..path.."' ?")
    end
  end

  local params_menu={
    {id="db",name="volume",min=-96,max=12,exp=false,div=0.1,default=-6,unit="db"},
    {id="rateMult",name="rate",min=-4,max=4,exp=false,div=0.01,default=1},
    {id="timescalein",name="speed",min=0.1,max=10,exp=true,div=0.1,default=1},
  }
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
    params:set_action(pram.id,function(x)
      if pram.id=="timescalein" then
        x=x*0.05
      end
      if pram.id=="rateMult" and math.abs(x)<0.1 then
        x=0.1*(x>0 and 1 or-1)
      end
      engine.setp(pram.id,x)
    end)
  end

  clock.run(function()
    while true do
      clock.sleep(1/10)
      redraw()
    end
  end)
  engine.sound_delta(PATH_TO_SAMPLES,2)
end

function key(k,z)
  if z==1 and k>1 then
    engine.sound_delta(PATH_TO_SAMPLES,k==2 and-1 or 1)
  end
end

encs={"db","rateMult","timescalein"}
function enc(k,d)
  params:delta(encs[k],d)
end

function cleanup()
  os.execute("pkill -f oscnotify")
  for k,v in pairs(reverb_settings_saved) do
    params:set(k,v)
  end
end

b_mod=2

function redraw()
  screen.clear()
  screen.blend_mode(b_mod)

  tree:redraw()

  local points={}
  for k,v in pairs(player) do
    r=util.linlin(0,1,3,16,v.amp)
    x=util.linlin(-1,1,r,128-r,v.lr)
    y=util.linlin(-1,1,r,64-r,v.fb)
    l=util.linlin(-12,0,10,1,20*math.log10(v.amp))
    table.insert(points,{x=x,y=y,r=r,used=false,l=util.round(l),on=v.on})
  end
  for _,point in ipairs(points) do
    if point.on==true then
      screen.level(point.l)
      screen.circle(point.x,point.y,point.r)
      screen.fill()
    end
  end
  screen.update()
end

function distance(p1,p2)
  local dx=p1.x-p2.x
  local dy=p1.y-p2.y
  return math.sqrt (dx*dx+dy*dy)
end

