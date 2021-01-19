--[[
-- Helper functions and defines for the Minerva Station campaigns
--]]
local vn = require 'vn'
local colour = require 'colour'
local portrait = require 'portrait'

local minerva = {
   -- Main Characters
   chicken = {
      name = _("Cyborg Chicken"),
      portrait = "cyborg_chicken.png",
      image = "cyborg_chicken.png",
      colour = nil,
   },
   maikki = {
      name = _("Maikki"),
      description = _("You see a very cutely dressed young woman. She seems to have a worried expression on her face."),
      portrait = "maikki.png",
      image = "maikki.png",
      colour = {1, 0.73, 0.97},
   },
   strangelove = {
      name = _("Dr. Strangelove"),
      portrait = "strangelove.png",
      image = "strangelove.png",
      colour = colour.FontPurple, -- Purplish (close to nebula?)
   },
   terminal = {
      name = _("Terminal"),
      description = _("A terminal with which you can check your current token balance and buy items with tokens."),
      portrait = "minerva_terminal.png",
      image = "minerva_terminal.png",
      colour = {0.8, 0.8, 0.8},
   },
   pirate = {
      name = _("Sketchy Individual"),
      portrait = "pirate/pirate5.png", -- REPLACE
      description = _("You see a sketchy-looking individual, they seem to have their gaze on you."),
      image = portrait.getFullPath("pirate/pirate5.png"),
   },

   log = {
      maikki = {
         idstr = "log_minerva_maikki",
         logname = _("Finding Maikki's Father"),
         logtype = _("Minerva Station"),
      },
      pirate = {
         idstr = "log_minerva_pirate",
         logname = _("Shady Jobs at Minerva"),
         logtype = _("Minerva Station"),
      },
   },
}

-- Helpers to create main characters
function minerva.vn_cyborg_chicken()
   return vn.Character.new( minerva.chicken.name,
         { image=minerva.chicken.image, color=minerva.chicken.colour } )
end
function minerva.vn_maikki()
   return vn.Character.new( minerva.maikki.name,
         { image=minerva.maikki.image, color=minerva.maikki.colour } )
end

-- Token stuff
-- Roughly 1 token is 1000 credits
function minerva.tokens_get()
   return var.peek( "minerva_tokens" ) or 0
end
function minerva.tokens_get_gained()
   return var.peek( "minerva_tokens_gained" ) or 0
end
function minerva.tokens_pay( amount )
   local v = minerva.tokens_get()
   var.push( "minerva_tokens", v+amount )
   -- Store lifetime earnings
   if amount > 0 then
      v = var.peek( "minerva_tokens_gained" ) or 0
      var.push( "minerva_tokens_gained", v+amount )
   end
end

-- Maikki stuff
function minerva.maikki_mood_get()
   return var.peek( "maikki_mood" ) or 0
end
function minerva.maikki_mood_mod( amount )
   var.push( "maikki_mood", minerva.maikki_mood_get()+amount )
end

return minerva
