-- Default task to run when idle
function idle ()
   if not mem.boss then -- Pilot never had a boss
      mem.boss = ai.getBoss()
   end

   -- If the boss exists, follow him
   if mem.boss and mem.boss:exists() then
      mem.angle = rnd.rnd( 360 )
      mem.radius = rnd.rnd( 70, 130 )
      ai.pushtask("follow_accurate",mem.boss)
   else  -- The pilot has no boss, he chooses his target
      local planet = ai.landplanet( mem.land_friendly )
      -- planet must exist.
      if planet == nil or mem.land_planet == false then
         ai.settimer(0, rnd.uniform(1, 3))
         ai.pushtask("enterdelay")
      else
         mem.land = planet:pos()
         ai.pushtask("hyperspace")
         if not mem.tookoff then
            ai.pushtask("land")
         end
      end

   end
end
