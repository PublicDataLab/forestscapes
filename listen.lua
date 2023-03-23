-- listen to the forest


engine.name = "Forestscapes1"
mod={0.2,0.5,0.3,-0.5}

function init() 
    print("starting")

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
    tree_scene()
    screen.update()
end



function tree_scene()
    local r=60
    local t=util.linlin(-1,1,3,2,mod[1])
    local x=r*math.sin(t)+64
    local y=r*math.cos(t)+64
    screen.level(math.floor(util.linlin(-1,1,15,1,mod[4])))
    screen.circle(x,y,10)
    screen.fill()
    local x=r*math.sin(t)+64-util.linlin(-1,1,20,2,mod[4])
    local y=r*math.cos(t)+64
    screen.level(0)
    screen.circle(x,y,10)
    screen.fill()
    tree_create()
  end
  
  function tree_rotate(x,y,a)
    local s,c=math.sin(a),math.cos(a)
    local a,b=x*c-y*s,x*s+y*c
    return a,b
  end
  
  function tree_branches(a,b,len,ang,dir,count,color)
    local period=math.random(5,20)
    local offset=math.random(5,20)
    local angle=27*math.pi/180*(util.linlin(-1,1,0.75,1.25,math.sin(clock.get_beat_sec()*clock.get_beats()/period+offset)))
    len=len*.66
    if count>8 then return end
    if len<3 then return end
    if dir>0 then ang=ang-angle
    else ang=ang+angle
    end
    local vx,vy=tree_rotate(0,len,ang)
    vx=a+vx;vy=b-vy
    math.randomseed(len)
    line(a,b,vx,vy,color)
    tree_branches(vx,vy,len+math.random()*2,ang,1,count+1,color)
    tree_branches(vx,vy,len+math.random()*2,ang,0,count+1,color)
  end
  
  function tree_create()
    local wid=110
    local hei=64
    local a,b=wid/2,hei-5
    line(wid/2,hei,a,b,15)
    math.randomseed(4)
    tree_branches(a,b,util.linlin(-1,1,5,30,mod[2])+math.random()*10,0,0,2,math.floor(util.linlin(-1,1,1,15,mod[2])))
    tree_branches(a,b,util.linlin(-1,1,5,30,mod[3])+math.random()*10,0,1,2,math.floor(util.linlin(-1,1,1,15,mod[3])))
  end
  
  
function line(x1,y1,x2,y2,level)
    screen.level(level)
    screen.move(x1,y1)
    screen.line(x2,y2)
    screen.stroke()
  end