-- forestscapes: grains
--
-- llllllll.co/t/forestscapes
--
-- granularization of
-- field recordings.
--

musicutil=require("musicutil")
tree_=include("lib/tree")
player_=include("lib/player")
engine.name="Forestscapes2"

total_num=6
player={}

function init()
  --os.execute(_path.code.."forestscapes/lib/oscnotify/run.sh &")
    params:set("reverb",2)
    params:set("rev_eng_input",0)
    params:set("rev_return_level",0)
    params:set("rev_low_time",9)
    params:set("rev_mid_time",6)


  tree = tree_:new{x=64,y=64,age=math.random(80,100)/100}
  player={}
  for i=1,total_num do
    table.insert(player,player_:new{id=i})
  end


  params:add_file("fileload", "load file", _path.code.."forestscapes/sounds/field")
  params:set_action("fileload",function(x)
    if (string.find(x,".ogg") or string.find(x,".wav")) then 
      engine.load_tape(1,x)
    end
  end)	

  local params_menu={
    {id="db",name="volume",min=-96,max=12,exp=false,div=0.1,default=-6,unit="db"},
    -- {id="bool",name="bool",min=0,max=1,exp=false,div=1,default=0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    -- {id="lpf",name="lpf",min=20,max=135,exp=false,div=0.5,default=135,formatter=function(param) return musicutil.note_num_to_freq(math.floor(param:get()),true)end},
    {id="rateMult",name="rate",min=0.1,max=4,exp=false,div=0.1,default=1},
    {id="timescalein",name="timescale",min=0.1,max=100,exp=true,div=0.1,default=1},
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
      engine.setp(pram.id,x)
      end)
  end

  params:bang()

  -- parameter debouncer
  debounce_fn={}

  -- setup osc
  osc_fun={
    oscnotify=function(args)
      print("file edited ok!")
      rerun()
    end,
    position=function(args)
      player[tonumber(args[1])].pos_current=tonumber(args[2])
    end,
    posStart=function(args)
      player[tonumber(args[1])].pos_start=tonumber(args[2])
    end,
    posEnd=function(args)
      player[tonumber(args[1])].pos_end=tonumber(args[2])
    end,
    volume=function(args)
      player[tonumber(args[1])].volume=tonumber(args[2])
    end,
    pan=function(args)
      player[tonumber(args[1])].pan=tonumber(args[2])
    end,
  }
  osc.event=function(path,args,from)
    if string.sub(path,1,1)=="/" then
      path=string.sub(path,2)
    end
    if osc_fun[path]~=nil then osc_fun[path](args) else
      -- print("osc.event: '"..path.."' ?")
    end
  end

  -- start redrawing clock
  clock.run(function()
    while true do
      debounce_params()
      clock.sleep(1/15)
      redraw()
    end
  end)

  clock.run(function()
    clock.sleep(0.2)
    params:set("fileload","/home/we/dust/code/forestscapes/sounds/field/aporee_11164_13177/RioUrubunightfallforest.ogg")
    clock.sleep(0.2)
    local rates={1,1,1,0.125/2,0.5,0.5,0.25,2,0.125}
    for i=1,total_num do
      engine.play_tape(1,i,rates[math.random(#rates)],0,1)
    end
  end)

  -- show_message("welcome")
end

function show_progress(val)
  show_message_progress=util.clamp(val,0,100)
end

function show_message(message,seconds)
  seconds=seconds or 2
  show_message_clock=10*seconds
  show_message_text=message
end

function draw_message()
  if show_message_clock~=nil and show_message_text~=nil and show_message_clock>0 and show_message_text~="" then
    show_message_clock=show_message_clock-1
    screen.blend_mode(0)

    local x=64
    local y=28
    local w=screen.text_extents(show_message_text)+8
    screen.rect(x-w/2,y,w+2,10)
    screen.level(0)
    screen.fill()
    screen.rect(x-w/2,y,w+2,10)
    screen.level(15)
    screen.stroke()
    screen.move(x,y+7)
    screen.level(10)
    screen.text_center(show_message_text)
    if show_message_progress~=nil and show_message_progress>0 then
      -- screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w*(show_message_progress/100)+2,9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
    else
      -- screen.update()
      screen.blend_mode(13)
      screen.rect(x-w/2,y,w+2,9)
      screen.level(10)
      screen.fill()
      screen.blend_mode(0)
      screen.level(0)
      screen.rect(x-w/2,y,w+2,10)
      screen.stroke()
    end
    if show_message_clock==0 then
      show_message_text=""
      show_message_progress=0
    end
  end
end

function debounce_params()
  for k,v in pairs(debounce_fn) do
    if v~=nil and v[1]~=nil and v[1]>0 then
      v[1]=v[1]-1
      if v[1]~=nil and v[1]==0 then
        if v[2]~=nil then
          local status,err=pcall(v[2])
          if err~=nil then
            print(status,err)
          end
        end
        debounce_fn[k]=nil
      else
        debounce_fn[k]=v
      end
    end
  end
end

function rerun()
  norns.script.load(norns.state.script)
end

function cleanup()
  os.execute("pkill -f oscnotify")
end

kon={false,false,false}

function key(k,z)
  kon[k]=z==1
end

encs={"db","rateMult","timescalein"}
function enc(k,d)
  params:delta(encs[k],d)
end

function redraw()
  screen.clear()
  tree:redraw()
  for _,p in ipairs(player) do
    p:redraw()
  end
  draw_message()
  screen.update()
end
