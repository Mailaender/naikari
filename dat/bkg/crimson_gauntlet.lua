--[[
   Crimson Gauntlet, Digital Battleground

   Some light circuit background.
--]]

-- We use the default background too!
require "bkg.default"
local bgshaders = require "bkg.bgshaders"

local love = require 'love'
local lg = require 'love.graphics'
local love_shaders = require 'love_shaders'

function background ()
   -- Initialize the shader
   shader = love_shaders.circuit{}
   bgshaders.init( shader )

   -- Default nebula background (no star)
   cur_sys = system.cur()
   prng:setSeed( cur_sys:name() )
   background_nebula()
end

function renderfg( dt )
   -- Get camera properties
   --local x, y = camera.get():get()
   local z = camera.getZoom()
   shader:send( "u_camera", 0, 0, z )

   local b = 0.1
   bgshaders.render( dt, {b, b, b, 0.02 * naev.conf().bg_brightness} )
end
