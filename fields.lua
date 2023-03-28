-- listen to the forest

tree_=include("lib/tree")
engine.name = "Forestscapes1"
mod={0.2,0.5,0.3,-0.5}

function init() 
    print("starting")

    trees={}
    for i=1,1 do 
        table.insert(trees,tree_:new())
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
    trees[1]:redraw()
    screen.update()
end


