local Player={}

function Player:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Player:init()
  self.pos_current=0.5
  self.pos_start=0
  self.pos_end=1
  self.volume=0
  self.pan=0
end

function Player:redraw()
  local spacing=4
  local height=64/total_num
  local y=(self.id-1)*height
  height=height-spacing
  y=y+(spacing/2)
  screen.blend_mode(2)
  screen.level(8)
  screen.rect(self.pos_current*128,y,1,height)
  screen.fill()
  screen.level(4)
  screen.rect((self.pan+1)*64,y,2,height)
  screen.fill()
  screen.level(util.round(util.linlin(0,1,1,6,self.volume)))
  screen.rect(self.pos_start*128,y,(self.pos_end-self.pos_start)*128,height)
  screen.fill()
end

return Player
