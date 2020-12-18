--[[
-- Math
--]]
local class = require 'class'
local prng = require 'prng'
local object = require 'love.object'

local function clamp01(x) return math.min(math.max(x, 0), 1) end
love_math = {}
love_math.RandomGenerator = class.inheritsFrom( object.Object )
love_math.RandomGenerator._type = "RandomGenerator"
function love_math.newRandomGenerator( low, high )
   if low ~= nil then
      low = 0xCBBF7A44
      high = 0x0139408D
   end
   local seed = tostring(low)
   if high ~= nil then
      seed = seed .. tostring(high)
   end
   local rng = love_math.RandomGenerator.new()
   rng:setSeed( seed )
   return rng
end
function love_math.RandomGenerator:setSeed( seed )
   prng.initHash( seed )
   self.z = prng.z
end
function love_math.RandomGenerator:random( min, max )
   -- TODO get rid of this horrible hack and make prng return objects
   prng.z = self.z
   if min == nil then
      return prng.num()
   elseif max == nil then
      return prng.range(1,min)
   else
      return prng.range(min,max)
   end
end
function love_math.RandomGenerator:getState() return self.z end
function love_math.RandomGenerator:setState( state ) self.z = state end
function love_math.random( min, max )
   if min == nil then
      return naev.rnd.rnd()
   elseif max == nil then
      return naev.rnd.rnd( min-1 )+1
   else
      return naev.rnd.rnd( min, max )
   end
end
function love_math.colorToBytes(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	r = floor(clamp01(r) * 255 + 0.5)
	g = floor(clamp01(g) * 255 + 0.5)
	b = floor(clamp01(b) * 255 + 0.5)
	a = a ~= nil and floor(clamp01(a) * 255 + 0.5) or nil
	return r, g, b, a
end
function love_math.colorFromBytes(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], r[4]
	end
	r = clamp01(floor(r + 0.5) / 255)
	g = clamp01(floor(g + 0.5) / 255)
	b = clamp01(floor(b + 0.5) / 255)
	a = a ~= nil and clamp01(floor(a + 0.5) / 255) or nil
	return r, g, b, a
end

return love_math
