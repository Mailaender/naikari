
--[[
-- music will get called with a string parameter indicating status
-- valid parameters:
--    load - game is loading
--    land - player landed
--    takeoff - player took off
--    combat - player just got a hostile onscreen
--    idle - current playing music ran out
]]--
last = "idle"

-- Faction-specific songs.
factional = {
   Collective = {"collective1", "automat"},
   Pirate = {"pirate1_theme1", "pirates_orchestra", "ambient4", "terminal"},
   Empire = {"empire1", "empire2"; add_neutral = true},
   Sirius = {"sirius1", "sirius2"; add_neutral = true},
   Dvaered = {"dvaered1", "dvaered2"; add_neutral = true},
   ["Za'lek"] = {"zalek1", "zalek2"; add_neutral = true},
   Thurion = {"motherload", "dark_city", add_neutral = true},
   Proteron = {"heartofmachine", "imminent_threat", "ambient4"},
}

-- Planet-specific songs
planet_songs = {
}

-- System-specific songs
system_ambient_songs = {
}

function choose( str )
   -- Stores all the available sound types and their functions
   local choose_table = {
      ["load"]    = choose_load,
      ["intro"]   = choose_intro,
      ["credits"] = choose_credits,
      ["land"]    = choose_ambient,
      ["takeoff"] = choose_ambient,
      ["ambient"] = choose_ambient,
      ["combat"]  = choose_combat
   }

   -- Don't change or play music if a mission or event doesn't want us to
   if var.peek( "music_off" ) then
      return
   end

   -- Allow restricting play of music until a song finishes
   if var.peek( "music_wait" ) then
      if music.isPlaying() then
         return
      else
         var.pop( "music_wait" )
      end
   end

   -- Means to only change song if needed
   if str == nil then
      str = "ambient"
   end

   local changed = false
   if str == "idle" then
      -- If selecting for idle, choose last music or ambient if last was
      -- takeoff music.
      if last ~= "idle" then
         -- We'll play the same as last unless it was takeoff
         if last == "takeoff" then
            changed = choose_ambient()
         else
            changed = choose(last)
         end
      else
         changed = choose_ambient()
         warn(_("'last' variable set to 'idle'; resetting to ambient."))
      end
   else
      -- Normal case
      changed = choose_table[str]()
   end

   if changed and str ~= "idle" then
      last = str -- save the last string so we can use it
   end
end


--[[
-- @brief Checks to see if a song is being played, if it is it stops it.
--
--    @return true if music is playing.
--]]
function checkIfPlayingOrStop( song )
   if music.isPlaying() then
      if music.current() ~= song then
         music.stop()
      end
      return true
   end
   return false
end


--[[
-- @brief Play a song if it's not currently playing.
--]]
function playIfNotPlaying( song )
   if checkIfPlayingOrStop( song ) then
      return true
   end
   music.load( song )
   music.play()
   return true
end


--[[
-- @brief Chooses Loading songs.
--]]
function choose_load ()
   return playIfNotPlaying( "machina" )
end


--[[
-- @brief Chooses Intro songs.
--]]
function choose_intro ()
   return playIfNotPlaying( "intro" )
end


--[[
-- @brief Chooses Credit songs.
--]]
function choose_credits ()
   return playIfNotPlaying( "empire1" )
end


--[[
-- @brief Chooses landing songs.
--]]
function choose_land ()
   local pnt   = planet.cur()
   local class = pnt:class()

   -- Planet override
   local override = planet_songs[ pnt:nameRaw() ]
   if override then
      music.load( override[ rnd.rnd(1, #override) ] )
      music.play()
      return true
   end

   -- Standard to do it based on type of planet
   if class == "M" then
      mus = { "agriculture" }
   elseif class == "O" then
      mus = { "ocean" }
   elseif class == "P" then
      mus = { "snow" }
   else
      if pnt:services()["inhabited"] then
         mus = { "cosmostation", "upbeat" }
      else
         mus = { "agriculture" }
      end
   end

   music.load( mus[ rnd.rnd(1, #mus) ] )
   music.play()
   return true
end


-- Takeoff songs
function choose_takeoff ()
   -- No need to restart
   if last == "takeoff" and music.isPlaying() then
      return true
   end
   takeoff = { "liftoff", "launch2", "launch3chatstart" }
   music.load( takeoff[ rnd.rnd(1,#takeoff) ])
   music.play()
   return true
end


-- Save old data
last_sysFaction = nil
last_sysNebuDens = nil
last_sysNebuVol = nil
ambient_neutral = {
   "ambient2", "mission", "peace1", "peace2", "peace4", "peace6",
   "void_sensor", "ambiphonic", "ambient4", "terminal", "eureka", "ambient2_5",
}
ambient_nebula = {"ambient1", "ambient3"}
--[[
-- @brief Chooses ambient songs.
--]]
function choose_ambient ()
   local force = true
   local add_neutral = false

   -- Check to see if we want to update
   if music.isPlaying() then
      if last == "takeoff" then
         -- This is a lie, but say we changed the music so it becomes
         -- the "last" value, for when music goes idle.
         return true
      elseif last == "ambient" then
         force = false
      end
   end

   -- Get information about the current system
   local sys = system.cur()
   local factions = sys:presences()
   local nebu_dens, nebu_vol = sys:nebula()

   local strongest = var.peek("music_ambient_force")

   if player.isLanded() then
      local pnt = planet.cur()

      -- Planet override
      local override = planet_songs[pnt:nameRaw()]
      if override then
         music.load(override[rnd.rnd(1, #override)])
         music.play()
         return true
      end

      if strongest == nil then
         if pnt:faction() ~= nil then
            strongest = pnt:faction():nameRaw()
         end
      end
   else
      -- System override
      local override = system_ambient_songs[sys:nameRaw()]
      if override then
         music.load(override[rnd.rnd(1, #override)])
         music.play()
         return true
      end
   end

   if strongest == nil then
      if factions then
         local strongest_amount = 0
         for k, v in pairs(factions) do
            if v > strongest_amount then
               strongest = k
               strongest_amount = v
            end
         end
      end
   end

   -- Check to see if changing faction zone
   if strongest ~= last_sysFaction then
      force = true
      last_sysFaction = strongest
   end

   -- Check to see if entering nebula
   local nebu = nebu_dens > 0
   if nebu ~= last_sysNebuDens then
      force = true
      last_sysNebuDens = nebu
   end
 
   -- Must be forced
   if force then
      -- Choose the music, bias by faction first
      local ambient = {}
      local add_neutral = true
      local neutral_prob = 0.6
      if strongest ~= nil and factional[strongest] ~= nil then
         ambient = factional[strongest]
         add_neutral = factional[strongest].add_neutral
      end

      -- Add generic songs if allowed.
      if add_neutral then
         local amcache = ambient
         ambient = {}
         for i, track in ipairs(amcache) do
            ambient[#ambient + 1] = track
         end
         local neut = nebu and ambient_nebula or ambient_neutral
         for i, track in ipairs(neut) do
            ambient[#ambient + 1] = track
         end
      end

      -- Make sure it's not already in the list or that we have to stop the
      -- currently playing song.
      if music.isPlaying() then
         local cur = music.current()
         for i, track in ipairs(ambient) do
            if cur == track then
               return false
            end
         end

         music.stop()
         if not player.isLanded() then
            return true
         end
      end

      -- Load music and play
      local new_track = ambient[rnd.rnd(1, #ambient)]

      -- Make it very unlikely (but not impossible) for the same music
      -- to play twice
      for i=1,3 do
         if new_track == last_track then
            new_track = ambient[rnd.rnd(1, #ambient)]
         else
            break
         end
      end

      last_track = new_track
      music.load( new_track )
      music.play()
      return true
   end

   return false
end


-- Faction-specific combat songs
factional_combat = {
   Collective = { "collective2", "galacticbattle", "battlesomething1", "combat3" },
   Pirate     = { "battlesomething2", "blackmoor_tides", add_neutral = true },
   Empire     = { "galacticbattle", "battlesomething2"; add_neutral = true },
   Goddard    = { "flf_battle1", "battlesomething1"; add_neutral = true },
   Dvaered    = { "flf_battle1", "battlesomething1", "battlesomething2"; add_neutral = true },
   ["FLF"]    = { "flf_battle1", "battlesomething2"; add_neutral = true },
   Frontier   = { "flf_battle1"; add_neutral = true },
   Sirius     = { "galacticbattle", "battlesomething1"; add_neutral = true },
   Soromid    = { "galacticbattle", "battlesomething2"; add_neutral = true },
   ["Za'lek"] = { "collective2", "galacticbattle", "battlesomething1", add_neutral = true }
}

--[[
-- @brief Chooses battle songs.
--]]
function choose_combat ()
   -- Get some data about the system
   local sys                  = system.cur()
   local nebu_dens, nebu_vol  = sys:nebula()
   
   local strongest = var.peek("music_combat_force")
   if strongest == nil then
      local presences = sys:presences()
      if presences then
         local strongest_amount = 0
         for k, v in pairs( presences ) do
            if faction.get(k):playerStanding() < 0 and v > strongest_amount then
               strongest = k
               strongest_amount = v
            end
         end
      end
   end

   local nebu = nebu_dens > 0
   if nebu then
      combat = { "nebu_battle1", "nebu_battle2", "combat1", "combat2" }
   else
      combat = { "combat3", "combat1", "combat2" }
   end

   if factional_combat[strongest] then
      if factional_combat[strongest].add_neutral then
         for k, v in ipairs( factional_combat[strongest] ) do
            combat[ #combat + 1 ] = v
         end
      else
         combat = factional_combat[strongest]
      end
   end

   -- Make sure it's not already in the list or that we have to stop the
   -- currently playing song.
   if music.isPlaying() then
      local cur = music.current()
      for k,v in pairs(combat) do
         if cur == v then
            return true
         end
      end

      music.stop()
      return true
   end

   local new_track = combat[ rnd.rnd(1,#combat) ]

   -- Make it very unlikely (but not impossible) for the same music
   -- to play twice
   for i=1, 3 do
      if new_track == last_track then
         new_track = combat[ rnd.rnd(1,#combat) ]
      else
         break
      end
   end

   last_track = new_track
   music.load( new_track )
   music.play()
   return true
end

