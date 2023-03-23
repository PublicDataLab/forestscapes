local Tree={}

function Tree:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Tree:init()
  math.randomseed(os.time())
  self.randseed=math.random(1,10)
  self.x=math.random(40,100)
  self.y=math.random(50,70)
  self.branchl=math.random(-100,100)/100
  self.branchr=self.branchl+math.random(-10,10)/100
  self.age=math.random()
  self.color=0
  self.coloring=math.random(4,15)
  self.active=true
end

function Tree:branches(a,b,len,ang,dir,count)
    local period=math.random(5,20)
    local offset=math.random(5,20)
    local angle=27*math.pi/180*(util.linlin(-1,1,0.75,1.25,math.sin(clock.get_beat_sec()*clock.get_beats()/period+offset)))
    len=len*util.linlin(0,1,0.55,0.68,self.age)
    if count>8 then return end
    if len<3 then return end
    if dir>0 then ang=ang-angle
    else ang=ang+angle
    end
    local vx,vy=self:rotate(0,len,ang)
    vx=a+vx;vy=b-vy
    math.randomseed(len)
    self:line(a,b,vx,vy,util.round(self.color))
    self:branches(vx,vy,len+math.random()*2,ang,1,count+1)
    self:branches(vx,vy,len+math.random()*2,ang,0,count+1)
  end
  
function Tree:rotate(x,y,a)
  local s,c=math.sin(a),math.cos(a)
  local a,b=x*c-y*s,x*s+y*c
  return a,b
end

function Tree:redraw()
  if not self.active and self.color==0 then 
    do return end 
  end
  if not self.active and self.color>0 then 
    self.color=self.color-0.5
  end
  if self.active and self.color<self.coloring then 
    self.color=self.color + 0.25
  end

    local wid=self.x
    local hei=self.y
    local a,b=wid/2,hei-5
    self:line(wid/2,hei,a,b,self.color)
    math.randomseed(self.randseed)
    self:branches(a,b,util.linlin(-1,1,5,30,self.branchl)+math.random()*10,0,0,2,math.floor(util.linlin(-1,1,1,15,self.branchl)))
    self:branches(a,b,util.linlin(-1,1,5,30,self.branchr)+math.random()*10,0,1,2,math.floor(util.linlin(-1,1,1,15,self.branchr)))
end

function Tree:line(x1,y1,x2,y2,level)
    screen.level(util.round(level))
    screen.move(x1,y1)
    screen.line(x2,y2)
    screen.stroke()
end

function Tree:activate(yes)
  self.active=yes 
end


return Tree
