local fmt = require "fmt"
require "ai/tpl/generic"
require "ai/personality/patrol"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true


function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 100, sprice / 25))

   -- Get refuel chance
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      mem.refuel = rnd.rnd( 2000, 4000 )
      if standing < 20 then
         mem.refuel_no = _("\"My fuel is property of the Empire.\"")
      elseif standing < 70 then
         if rnd.rnd() > 0.2 then
            mem.refuel_no = _("\"My fuel is property of the Empire.\"")
         end
      else
         mem.refuel = mem.refuel * 0.6
      end
      -- Most likely no chance to refuel
      mem.refuel_msg = fmt.f(
            _("\"I suppose I could spare some fuel for {credits}.\""),
            {credits=fmt.credits(mem.refuel)})
   end

   -- See if can be bribed
   if rnd.rnd() > 0.7 then
      mem.bribe = math.sqrt(ai.pilot():stats().mass) * (500.*rnd.rnd() + 1750.)
      mem.bribe_prompt = fmt.f(
            _("\"For {credits} I could forget about seeing you.\""),
            {credits=fmt.credits(mem.bribe)})
      mem.bribe_paid = _("\"Now scram before I change my mind.\"")
   else
     bribe_no = {
            _("\"You won't buy your way out of this one.\""),
            _("\"The Empire likes to make examples out of scum like you.\""),
            _("\"You've made a huge mistake.\""),
            _("\"Bribery carries a harsh penalty, scum.\""),
            _("\"I'm not interested in your blood money!\""),
            _("\"All the money in the world won't save you now!\"")
     }
     mem.bribe_no = bribe_no[ rnd.rnd(1,#bribe_no) ]
     
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt ( target, offense )

   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 then
      return
   end

   -- some taunts
   if offense then
      taunts = {
            _("There is no room in this universe for scum like you!"),
            _("The Empire will enjoy your death!"),
            _("Your head will make a fine gift for the Emperor!"),
            _("None survive the wrath of the Emperor!"),
            _("Enjoy your last moments, criminal!")
      }
   else
      taunts = {
            _("You dare attack me?!"),
            _("You are no match for the Empire!"),
            _("The Empire will have your head!"),
            _("You'll regret that!"),
            _("That was a fatal mistake!")
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


