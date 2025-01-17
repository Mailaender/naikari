require("ai/tpl/generic")
require("ai/personality/patrol")
require "numstring"

-- Settings
mem.armour_run = 40
mem.armour_return = 70
mem.aggressive = true


function create ()
   local p = ai.pilot()
   local price = p:ship():price()
   ai.setcredits(rnd.rnd(price / 100, price / 25))

   if rnd.rnd() > 0.7 then
      mem.bribe = math.sqrt(p:stats().mass) * (750. * rnd.rnd() + 2500.)
      mem.bribe_prompt = string.format(_("\"Your life is worth %s to me.\""),
            creditstring(mem.bribe))
      mem.bribe_paid = _("\"Beat it.\"")
   else
      if rnd.rnd() > 0.5 then
         mem.bribe_no = _("\"You won't buy your way out of this one.\"")
      else
         mem.bribe_no = _("\"I'm afraid you can't make it worth my while.\"")
      end
   end

   -- Refuel
   mem.refuel = rnd.rnd(3000, 5000)
   local pp = player.pilot()
   if pp:exists() then
      mem.refuel_msg = string.format(
            _("\"I'll supply your ship with fuel for %s.\""),
            creditstring(mem.refuel))
   end

   mem.loiter = 3 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Finish up creation
   create_post()
end

-- taunts
function taunt ( target, offense )

   -- Only 20% of actually taunting.
   if rnd.rnd(0,4) ~= 0 then
      return
   end

   -- some taunts
   if offense then
      taunts = {
            _("Don't take this personally."),
            _("It's just business.")
      }
   else
      taunts = {
            _("Your skull will make a great hood ornament."),
            _("I've destroyed ships twice the size of yours!"),
            _("I'll crush you like a grape!"),
            _("This isn't what I signed up for!")
      }
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


