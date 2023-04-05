-- listen to the forest

tree_=include("lib/tree")
engine.name = "Forestscapes1"
player = {}

function init() 
    print("starting")
    
  tree = tree_:new{x=64,y=50,age=0.7}

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
    if osc_fun[path]~=nil then osc_fun[path](args) else
      -- print("osc.event: '"..path.."' ?")
    end
  end

    local params_menu={
    }
    for i=1,4 do 
        table.insert(params_menu,{id="mod"..i,name="mod"..i,modi=i,min=-1,max=1,exp=false,div=0.1,default=0,unit="db"})
    end
    for _,pram in ipairs(params_menu) do
        params:add{
            type="control",
            id=pram.id,
            name=pram.name,
            controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,pram.unit or "",pram.div/(pram.max-pram.min)),
            formatter=pram.formatter,
        }
        params:set_action(pram.id,function(x) 
            if pram.modi~=nil then 
                mod[pram.modi]=x
            end
        end)
    end

    clock.run(function()
        while true do 
            clock.sleep(1/10)
            redraw()
        end
    end)
end

function key(k,z)
end

function enc(k,d)
    engine.sound_delta(d)
end

function redraw()
    screen.clear()
    screen.blend_mode(3)

    tree:redraw()

    local points={}
    for k,v in pairs(player) do 
        x=util.linlin(-1,1,0,128,v.lr)
        y=util.linlin(-1,1,0,64,v.fb)
        r=util.linlin(0,1,3,16,v.amp)
        table.insert(points,{x=x,y=y,r=r,used=false})
    end
    for _, point in ipairs(points) do 
        screen.circle(point.x,point.y,point.r)
        screen.fill()
    end
    screen.update()
end


function distance(p1,p2)
    local dx = p1.x-p2.x
    local dy = p1.y-p2.y
    return math.sqrt ( dx * dx + dy * dy )
end

