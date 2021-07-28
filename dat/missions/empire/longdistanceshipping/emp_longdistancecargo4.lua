--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Frontier Long Distance Recruitment">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>4</priority>
  <cond>faction.playerStanding("Empire") &gt;= 0</cond>
  <chance>75</chance>
  <done>Za'lek Long Distance Recruitment</done>   
  <location>Bar</location>
  <faction>Empire</faction>
 </avail>
 <notes>
  <campaign>Empire Shipping</campaign>
 </notes>
</mission> 
--]]
--[[

   Fourth diplomatic mission to Frontier space that opens up the Empire long-distance cargo missions.

   Author: micahmumper

]]--

require "numstring"
require "jumpdist"
require "missions/empire/common"

bar_desc = _("Lieutenant Czesc from the Empire Armada Shipping Division is sitting at the bar.")
misn_title = _("Frontier Long Distance Recruitment")
misn_desc = _("Land on The Frontier Council (Gilligan's Light system) to deliver a shipping diplomat")
title = {}

text = {}
text[1] = _([["We have to stop running into each other like this." Lieutenant Czesc laughs at his joke. "Just kidding, you know I owe you for helping set up these contracts. So far, everything has been moving smoothly on our end. We're hoping to extend our relations to the Frontier Alliance. You know the drill by this point. Ready to help?"]])
text[2] = _([["I applaud your commitment," Lieutenant Czesc says, "and I know these aren't the most exciting missions, but they're most useful. The frontier can be a bit dangerous, so make sure you're prepared. You need to drop the bureaucrat off at The Frontier Council in Gilligan's Light system. After this, there should only be one more faction to bring into the fold. I expect to see you again soon."]])
text[3] = _([[You deliver the diplomat to The Frontier Council, and she hands you a credit chip. Thankfully, Lieutenant Czesc mentioned only needing your assistance again for one more mission. This last bureaucrat refused to stay in her quarters, preferring to hang out on the bridge and give you the ins and outs of Empire bureaucracy. Only your loyalty to the Empire stopped you from sending her out into the vacuum of space.]])

log_text = _([[You delivered a shipping bureaucrat to The Frontier Council for the Empire. Thankfully, Lieutenant Czesc mentioned only needing your assistance again for one more mission. This last bureaucrat refused to stay in her quarters, preferring to hang out on the bridge and give you the ins and outs of Empire bureaucracy. Only your loyalty to the Empire stopped you from sending her out into the vacuum of space.]])


function create ()
 -- Note: this mission does not make any system claims.
 
      -- Get the planet and system at which we currently are.
   startworld, startworld_sys = planet.cur()

   -- Set our target system and planet.
   targetworld_sys = system.get("Gilligan's Light")
   targetworld = planet.get("The Frontier Council")

   misn.setNPC(_("Lieutenant"), "empire/unique/czesc.png", bar_desc)
end


function accept ()
   -- Set marker to a system, visible in any mission computer and the onboard computer.
   misn.markerAdd(targetworld_sys, "low")
   ---Intro Text
   if not tk.yesno("", text[1]) then
      misn.finish()
   end
   -- Flavour text and mini-briefing
   tk.msg("", text[2])
   ---Accept the mission
   misn.accept()
  
   -- Description is visible in OSD and the onboard computer, it shouldn't be too long either.
   reward = 500000 -- 500K
   misn.setTitle(misn_title)
   misn.setReward(creditstring(reward))
   misn.setDesc(string.format(misn_desc, targetworld:name(), targetworld_sys:name()))
   misn.osdCreate(misn_title, {misn_desc})
   -- Set up the goal
   hook.land("land")
   person = misn.cargoAdd("Person" , 0)
end


function land()

   if planet.cur() == targetworld then
         misn.cargoRm(person)
         player.pay(reward)
         -- More flavour text
         tk.msg("", text[3])
         faction.modPlayerSingle("Empire",3)
         emp_addShippingLog(log_text)
         misn.finish(true)
   end
end

function abort()
   misn.finish(false)
end
