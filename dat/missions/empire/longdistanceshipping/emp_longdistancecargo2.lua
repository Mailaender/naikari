--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Dvaered Long Distance Recruitment">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>4</priority>
  <cond>faction.playerStanding("Empire") &gt;= 0</cond>
  <chance>75</chance>
  <done>Soromid Long Distance Recruitment</done>   
  <location>Bar</location>
  <faction>Empire</faction>
 </avail>
 <notes>
  <campaign>Empire Shipping</campaign>
 </notes>
</mission> 
--]]
--[[

   Second diplomatic mission to Dvaered space that opens up the Empire long-distance cargo missions.

   Author: micahmumper

]]--

require "numstring"
require "jumpdist"
require "missions/empire/common"

bar_desc = _("Lieutenant Czesc from the Empire Armada Shipping Division is sitting at the bar.")
misn_title = _("Dvaered Long Distance Recruitment")
misn_desc = _("Land on Praxis (Ogat system) to deliver a shipping diplomat")

text = {}
text[1] = _([[Lieutenant Czesc waves you over when he notices you enter the bar. "I knew we would run into each other soon enough. Great job delivering that bureaucrat. We should be up and running in Soromid space in no time!" He presses a button on his wrist computer. "We're hoping to expand to Dvaered territory next. Can I count on your help?"]])
text[2] = _([["Great!" says Lieutenant Czesc. "I'll send a message to the bureaucrat to meet you at the hanger. The Dvaered are, of course, allies of the Empire. Still, they offend easily, so try not to talk too much. Your mission is to drop the bureaucrat off on Praxis in the Ogat system. He will take it from there and report back to me when the shipping contract has been confirmed. Afterwards, keep an eye out for me in Empire space and we can continue the operation."]])
text[3] = _([[You drop the bureaucrat off on Praxis, and he hands you a credit chip. You remember Lieutenant Czesc told you to look for him on Empire controlled planets after you finish.]])

log_text = _([[You delivered a shipping bureaucrat to Praxis for the Empire. Lieutenant Czesc told you to look for him on Empire controlled planets after you finish.]])


function create ()
 -- Note: this mission does not make any system claims.
 
      -- Get the planet and system at which we currently are.
   startworld, startworld_sys = planet.cur()

   -- Set our target system and planet.
   targetworld_sys = system.get("Ogat")
   targetworld = planet.get("Praxis")


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
   misn.osdCreate("", {misn_desc})
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
