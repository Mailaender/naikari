require("ai/tpl/generic")
require("ai/personality/patrol")
require "numstring"

-- Settings
mem.aggressive = true


-- Create function
function create ()
   sprice = ai.pilot():ship():price()
   ai.setcredits(rnd.rnd(sprice / 100, sprice / 10))

   -- Bribing
   bribe_no = {
         _("\"You insult my honor.\""),
         _("\"I find your lack of honor disturbing.\""),
         _("\"You disgust me.\""),
         _("\"Bribery carries a harsh penalty.\""),
         _("\"House Goddard does not lower itself to common scum.\"")
   }
   mem.bribe_no = bribe_no[ rnd.rnd(1,#bribe_no) ]

   -- Refueling
   local p = player.pilot()
   if p:exists() then
      local standing = ai.getstanding( p ) or -1
      mem.refuel = rnd.rnd( 2000, 4000 )
      if standing > 60 then mem.refuel = mem.refuel * 0.7 end
      mem.refuel_msg = string.format( _("\"I could do you the favor of refueling for the price of %s.\""),
            creditstring(mem.refuel) )
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt ( target, offense )
   -- Offense is not actually used
   taunts = {
         _("Prepare to face annihilation!"),
         _("I shall wash my hull in your blood!"),
         _("Your head will make a great trophy!"),
         _("These moments will be your last!"),
         _("You are a parasite!")
   }
   ai.pilot():comm( target, taunts[ rnd.rnd(1,#taunts) ] )
end

