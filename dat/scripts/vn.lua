--[[
-- Visual Novel API for Naev
--
-- Based on Love2D API
--]]
local utf8 = require 'utf8'

local vn = {
   speed = 0.04,
   color = {1,1,1},

   -- Internal usage
   _characters = {},
   _states = {},
   _state = 0,
   _bufcol = { 1, 1, 1 },
   _buffer = "",
   _title = nil,
   _alpha = 1,
}
-- Drawing
vn.textbox_font = love.graphics.newFont(16)
vn.textbox_w = 800
vn.textbox_h = 200
vn.textbox_x = (love.w-vn.textbox_w)/2
vn.textbox_y = love.h-230
vn.textbox_bg = {0, 0, 0, 1}
vn.namebox_font = love.graphics.newFont(20)
vn.namebox_w = -1 -- Autosize
vn.namebox_h = 20*2+vn.namebox_font:getHeight()
vn.namebox_x = vn.textbox_x
vn.namebox_y = vn.textbox_y - vn.namebox_h - 20
vn.namebox_bg = vn.textbox_bg


function vn._checkstarted()
   if vn._started then
      error( _("vn: can't modify states when running") )
   end
end

local function _set_col( col )
   local a = col[4] or 1
   love.graphics.setColor( col[1], col[2], col[3], a*vn._alpha )
end

local function _draw_bg( x, y, w, h, col, border_col )
   col = col or {0, 0, 0, 1}
   border_col = border_col or {0.5, 0.5, 0.5, 1}
   _set_col( border_col )
   love.graphics.rectangle( "fill", x, y, w, h )
   _set_col( col )
   love.graphics.rectangle( "fill", x+2, y+2, w-4, h-4 )
end

function vn.draw()
   -- Draw characters
   -- TODO handle multiple characters and characters appearing in the middle
   -- of conversations
   for k,c in ipairs( vn._characters ) do
      if c.image ~= nil then
         local w, h = c.image:getDimensions()
         local lw, lh = love.window.getDimensions()
         local mw, mh = vn.textbox_w, vn.textbox_y
         local scale = math.min( mw/w, mh/h )
         local col
         if c.talking then
            col = { 1, 1, 1 }
         else
            col = { 0.8, 0.8, 0.8 }
         end
         _set_col( col )
         local x = (lw-w*scale)/2
         local y = mh-scale*h
         love.graphics.draw( c.image, x, y, 0, scale, scale )
      end
   end

   -- Textbox
   local font = vn.textbox_font
   -- Draw background
   local x, y, w, h = vn.textbox_x, vn.textbox_y, vn.textbox_w, vn.textbox_h
   local bw = 20
   local bh = 20
   _draw_bg( x, y, w, h, vn.textbox_bg )
   -- Draw text
   _set_col( vn._bufcol )
   love.graphics.printf( vn._buffer, font, x+bw, y+bw, vn.textbox_w-bw )

   -- Namebox
   if vn._title ~= nil and utf8.len(vn._title)>0 then
      font = vn.namebox_font
      bw = 20
      bh = 20
      x = vn.namebox_x
      y = vn.namebox_y
      w = vn.namebox_w
      h = vn.namebox_h
      if w < 0 then
         w = font:getWidth( vn._title )+2*bw
      end
      _draw_bg( x, y, w, h, vn.namebox_bg )
      -- Draw text
      _set_col( vn._bufcol )
      love.graphics.print( vn._title, font, x+bw, y+bh )
   end

   -- Draw if necessary
   if vn.isDone() then return end
   local s = vn._states[ vn._state ]
   s:draw()
end

function vn.update(dt)
   -- Out of states
   if vn._state > #vn._states then
      love.event.quit()
      return
   end

   if vn.isDone() then return end

   if vn._state < 0 then
      vn._state = 1
   end

   local s = vn._states[ vn._state ]
   s:update( dt )
end

function vn.keypressed( key )
   if key=="escape" then
      love.event.quit()
      return
   end

   if vn.isDone() then return end
   local s = vn._states[ vn._state ]
   s:key( key )
end

function vn.mousepressed( mx, my, button )
   if vn.isDone() then return end
   local s = vn._states[ vn._state ]
   s:click( mx, my, button )
end


-- Helpers
function vn.me( what, nowait ) vn.say( "me", what, nowait ) end
function vn.na( what, nowait ) vn.say( "narrator", what, nowait ) end

--[[
-- State
--]]
vn.State = {}
vn.State_mt = { __index = vn.State }
local function _dummy() end
local function _finish(self) self._done = true end
local function _inbox( mx, my, x, y, w, h )
   return (mx>=x and mx<= mx+w and my>=y and my<=y+h)
end
function vn.State.new()
   local s = {}
   setmetatable( s, vn.State_mt )
   s._type = "State"
   s._init = _dummy
   s._draw = _dummy
   s._update = _dummy
   s._click = _dummy
   s._key = _dummy
   s._done = false
   return s
end
function vn.State:type() return self._type end
function vn.State:init()
   self._done = false
   self:_init()
end
function vn.State:draw()
   self:_draw()
   vn._checkDone()
end
function vn.State:update( dt )
   self:_update( dt )
   vn._checkDone()
end
function vn.State:click( mx, my, button )
   self:_click( mx, my, button )
   vn._checkDone()
end
function vn.State:key( key )
   self:_key( key )
   vn._checkDone()
end
function vn.State:isDone() return self._done end
--[[
-- Scene
--]]
vn.StateScene ={}
function vn.StateScene.new( background )
   local s = vn.State.new()
   s._init = vn.StateScene._init
   s._type = "Scene"
   return s
end
function vn.StateScene:_init()
   -- Reset characters
   vn._characters = {
      vn._me,
      vn._na
   }
   _finish(self)
end
--[[
-- Character
--]]
vn.StateCharacter ={}
function vn.StateCharacter.new( character )
   local s = vn.State.new()
   s._init = vn.StateCharacter._init
   s._type = "Character"
   s.character = character
   return s
end
function vn.StateCharacter:_init()
   table.insert( vn._characters, self.character )
   _finish(self)
end
--[[
-- Say
--]]
vn.StateSay = {}
function vn.StateSay.new( who, what )
   local s = vn.State.new()
   s._init = vn.StateSay._init
   s._update = vn.StateSay._update
   s._click = vn.StateSay._finish
   s._key = vn.StateSay._finish
   s._type = "Say"
   s.who = who
   s.what = what
   return s
end
function vn.StateSay:_init()
   self._timer = vn.speed
   self._len = utf8.len( self.what )
   self._pos = utf8.next( self.what )
   self._text = ""
   local c = vn._getCharacter( self.who )
   vn._bufcol = c.color
   vn._buffer = self._text
   if c.hidetitle then
      vn._title = nil
   else
      vn._title = c.who
   end
   -- Reset talking
   for k,v in ipairs( vn._characters ) do
      v.talking = false
   end
   c.talking = true
end
function vn.StateSay:_update( dt )
   self._timer = self._timer - dt
   while self._timer < 0 do
      -- No more characters left -> done!
      if utf8.len(self._text) == self._len then
         _finish( self )
         return
      end
      self._pos = utf8.next( self.what, self._pos )
      self._text = string.sub( self.what, 1, self._pos )
      self._timer = self._timer + vn.speed
      vn._buffer = self._text
   end
end
function vn.StateSay:_finish()
   self._text = self.what
   vn._buffer = self._text
   _finish( self )
end
--[[
-- Wait
--]]
vn.StateWait ={}
function vn.StateWait.new()
   local s = vn.State.new()
   s._init = vn.StateWait._init
   s._draw = vn.StateWait._draw
   s._click = _finish
   s._key = _finish
   s._type = "Wait"
   return s
end
function vn.StateWait:_init()
   local x, y, w, h = vn.textbox_x, vn.textbox_y, vn.textbox_w, vn.textbox_h
   local font = vn.namebox_font
   self._font = font
   self._text = ">"
   self._w = font:getWidth( self._text )
   self._h = font:getHeight()
   self._x = x+w-10-self._w
   self._y = y+h-10-self._h
end
function vn.StateWait:_draw()
   _set_col( vn._bufcol )
   love.graphics.print( self._text, self._font, self._x, self._y )
end
--[[
-- Menu
--]]
vn.StateMenu = {}
function vn.StateMenu.new( items, handler )
   local s = vn.State.new()
   s._init = vn.StateMenu._init
   s._draw = vn.StateMenu._draw
   s._click = vn.StateMenu._click
   s._key = vn.StateMenu._key
   s._type = "Menu"
   s.items = items
   s.handler = handler
   s._choose = vn.StateMenu._choose
   return s
end
function vn.StateMenu:_init()
   -- Set up the graphics stuff
   local font = vn.namebox_font
   -- Border information
   local tb = 15 -- Inner border around text
   local b = 15 -- Outter border
   self._tb = tb
   self._b = b
   -- Get longest line
   local w = 0
   local h = 0
   self._elem = {}
   for k,v in ipairs(self.items) do
      local text = string.format("%d. %s", k, v[1])
      local sw, wrapped = font:getWrap( text, 900 )
      sw = sw + 2*tb
      local sh =  2*tb + font:getHeight() + font:getLineHeight() * (#wrapped-1)
      local elem = { text, 0, h, sw, sh }
      if w < sw then
         w = sw
      end
      h = h + sh + b
      self._elem[k] = elem
   end
   self._w = w
   self._h = h-b
   self._x = (love.w-w)/2
   self._y = (love.h-h)/2-100
end
function vn.StateMenu:_draw()
   local font = vn.namebox_font
   local gx, gy, gw, gh = self._x, self._y, self._w, self._h
   local b = self._b
   _draw_bg( gx-b, gy-b, gw+2*b, gh+2*b )
   local tb = self._tb
   local mx, my = love.mouse.getX(), love.mouse.getY()
   for k,v in ipairs(self._elem) do
      local text, x, y, w, h = unpack(v)
      local col
      if _inbox( mx, my, gx+x, gy+y, w, h ) then
         col = {0.5, 0.5, 0.5}
      else
         col = {0.2, 0.2, 0.2}
      end
      _set_col( col )
      love.graphics.rectangle( "fill", gx+x, gy+y, w, h )
      _set_col( {1, 1, 1} )
      love.graphics.print( text, font, gx+x+tb, gy+y+tb )
   end
end
function vn.StateMenu:_click( mx, my, button )
   if button ~= 1 then
      return
   end
   local gx, gy = self._x, self._y
   local b = self._tb
   for k,v in ipairs(self._elem) do
      local text, x, y, w, h = unpack(v)
      if _inbox( mx, my, gx+x-b, gy+y-b, w+2*b, h+2*b ) then
         self:_choose(k)
         return
      end
   end
end
function vn.StateMenu:_key( key )
   local n = tonumber(key)
   if n == nil then return end
   if n==0 then n = n + 10 end
   if n > #self.items then return end
   self:_choose(n)
end
function vn.StateMenu:_choose( n )
   self.handler( self.items[n][2] )
   _finish( self )
end
--[[
-- Label
--]]
vn.StateLabel ={}
function vn.StateLabel.new( label )
   local s = vn.State.new()
   s._init = _finish
   s._type = "Label"
   s.label = label
   return s
end
--[[
-- Jump
--]]
vn.StateJump ={}
function vn.StateJump.new( label )
   local s = vn.State.new()
   s._init = vn.StateJump._init
   s._type = "Jump"
   s.label = label
   return s
end
function vn.StateJump:_init()
   vn._jump( self.label )
   _finish(self)
end
--[[
-- Start
--]]
vn.StateStart ={}
function vn.StateStart.new()
   local s = vn.State.new()
   s._init = _finish
   s._type = "Start"
   return s
end
--[[
-- End
--]]
vn.StateEnd ={}
function vn.StateEnd.new()
   local s = vn.State.new()
   s._init = vn.StateEnd._init
   s._type = "End"
   return s
end
function vn.StateEnd:_init()
   vn._state = #vn._states+1
end
--[[
-- Fade-In
--]]
vn.StateFade ={}
function vn.StateFade.new( seconds, fadestart, fadeend )
   seconds = seconds or 0.2
   local s = vn.State.new()
   s._init = vn.StateFade._init
   s._update = vn.StateFade._update
   s._type = "Fade"
   s._start = fadestart
   s._end = fadeend
   s._inc = s._end > s._start
   s._fadetime = 1/seconds
   if not s._inc then
      s._fadetime = -s._fadetime
   end
   return s
end
function vn.StateFade:_init()
   vn._alpha = self._start
end
function vn.StateFade:_update(dt)
   vn._alpha = vn._alpha + dt * self._fadetime
   if (self._inc and vn._alpha > self._end) or
         (not self._inc and vn._alpha < self._end) then
      vn._alpha = self._end
      _finish(self)
   end
end


--[[
-- Character
--]]
vn.Character = {}
function vn.Character:say( what, nowait ) return vn.say( self.who, what, nowait ) end
vn.Character_mt = { __index = vn.Character, __call = vn.Character.say }
function vn.Character.new( who, params )
   local c = {}
   setmetatable( c, vn.Character_mt )
   params = params or {}
   c.who = who
   c.color = params.color or vn._default.color
   local image = params.image
   if type(image)=='string' then
      image = love.graphics.newImage( image )
   end
   c.image = image
   c.hidetitle = params.hidetitle
   c.params = params
   return c
end
function vn.newCharacter( who, params )
   local c
   if type(who)=="string" then
      c = vn.Character.new( who, params )
   else
      c = who
   end
   table.insert( vn._states, vn.StateCharacter.new( c ) )
   return c
end

function vn.scene( background )
   vn._checkstarted()
   table.insert( vn._states, vn.StateScene.new( background ) )
end

function vn.say( who, what, nowait )
   vn._checkstarted()
   table.insert( vn._states, vn.StateSay.new( who, what ) )
   if not nowait then
      table.insert( vn._states, vn.StateWait.new() )
   end
end

function vn.menu( items, handler )
   vn._checkstarted()
   handler = handler or vn.jump
   table.insert( vn._states, vn.StateMenu.new( items, handler ) )
end

function vn.label( label )
   vn._checkstarted()
   table.insert( vn._states, vn.StateLabel.new( label ) )
end

function vn.jump( label )
   if vn._started then
      vn._jump( label )
   end
   table.insert( vn._states, vn.StateJump.new( label ) )
end

function vn.done()
   vn._checkstarted()
   table.insert( vn._states, vn.StateEnd.new() )
end

function vn.scene()
   vn._checkstarted()
   table.insert( vn._states, vn.StateScene.new() )
end

function vn.fade( seconds, fadestart, fadeend )
   vn._checkstarted()
   table.insert( vn._states, vn.StateFade.new( seconds, fadestart, fadeend ) )
end
function vn.fadein( seconds ) vn.fade( seconds, 0, 1 ) end
function vn.fadeout( seconds ) vn.fade( seconds, 1, 0 ) end

function vn._jump( label )
   for k,v in ipairs(vn._states) do
      if v:type() == "Label" and v.label == label then
         vn._state = k
         local s = vn._states[ vn._state ]
         s:init()
         vn._checkDone()
         return true
      end
   end
   error( string.format(_("vn: unable to find label '%s'"), label ) )
   return false
end

function vn._getCharacter( who )
   for k,v in ipairs(vn._characters) do
      if v.who == who then
         return v
      end
   end
   error( string.format(_("vn: character '%s' not found!"), who) )
end

function vn._checkDone()
   if vn.isDone() then return end

   local s = vn._states[ vn._state ]
   if s:isDone() then
      vn._state = vn._state+1
      if vn._state > #vn._states then
         return
      end
      s = vn._states[ vn._state ]
      s:init()
      vn._checkDone() -- Recursive :D
   end
end

function vn.isDone()
   return vn._state > #vn._states
end

function vn.run()
   if #vn._states == 0 then
      error( _("vn: run without any states") )
   end
   love._vn = true
   love.exec( 'scripts/vn' )
end

-- Default characters
vn._me = vn.Character.new( "me", { color={1, 1, 1}, hidetitle=true } )
vn._na = vn.Character.new( "narrator", { color={0.5, 0.5, 0.5}, hidetitle=true } )

return vn
