-- skeleton
musicutil=require("musicutil")
player_=include("lib/player")
engine.name="Forestscapes2"

total_num=6
player={}

function init()
  os.execute(_path.code.."forestscapes/lib/oscnotify/run.sh &")

  player={}
  for i=1,total_num do
    table.insert(player,player_:new{id=i})
  end

  local params_menu={
    {id="volume",name="volume",min=-96,max=12,exp=false,div=0.1,default=-6,unit="db"},
    {id="bool",name="bool",min=0,max=1,exp=false,div=1,default=0,response=1,formatter=function(param) return param:get()==1 and "yes" or "no" end},
    {id="lpf",name="lpf",min=20,max=135,exp=false,div=0.5,default=135,formatter=function(param) return musicutil.note_num_to_freq(math.floor(param:get()),true)end},
    {id="res",name="res",min=0.01,max=1,exp=false,div=0.01,default=0.71},
  }
  for _,pram in ipairs(params_menu) do
    params:add{
      type="control",
      id=pram.id,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=pram.formatter,
    }
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
    engine.load_tape(1,"/home/we/dust/audio/windchimes.wav")
    clock.sleep(0.2)
    for i=1,total_num do
      engine.play_tape(1,i,1,0,1)
    end
  end)

  show_message("welcome")
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

function enc(k,d)

end

function redraw()
  screen.clear()
  for _,p in ipairs(player) do
    p:redraw()
  end
  draw_message()
  screen.update()
end
