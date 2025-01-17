--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Pirate Shipping">
 <avail>
  <priority>70</priority>
  <cond>faction.playerStanding("Pirate") &gt;= 0</cond>
  <chance>960</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Handles the randomly generated Pirate cargo missions.

   Most of the code taken from Empire Shipping.

]]--

local fmt = require "fmt"
require "cargo_common"


misn_desc = _("Pirate cargo transport of contraband goods to {planet} in the {system} system.")

msg_timeup = _("MISSION FAILED: You have failed to deliver the goods on time!")

osd_title = _("Pirate Shipping")
osd_msg1 = _("Land on {planet} ({system} system) before {deadline}\n({time} remaining)")

-- Use hidden jumps
cargo_use_hidden = true

-- Always available
cargo_always_available = true

--[[
--   Pirates shipping missions are always timed, but quite lax on the schedules
--   and pays a lot more then the rush missions
--]]


-- This is in cargo_common, but we need to increase the range
function cargo_selectMissionDistance ()
   return rnd.rnd(3, 10)
end


function create()
   -- Note: this mission does not make any system claims.

   origin_p, origin_s = planet.cur()
   local routesys = origin_s
   local routepos = origin_p:pos()

   -- target destination
   destplanet, destsys, numjumps, traveldist, cargo, avgrisk, tier = cargo_calculateRoute()
   if destplanet == nil or destplanet:faction() == faction.get("Pirate") then
      misn.finish(false)
   end

   -- We’re redefining the cargo
   local cargoes = {
      {
         N_("Unmarked Boxes"),
         N_("A collection of unmarked boxes you were not told the contents of.")
      },
      {
         N_("Weapons"),
         N_("Assorted crates of illegally sourced weapons to be sold on the black market.")
      },
      {
         N_("Drugs"),
         N_("A collection of various illegal drugs that will surely net a large profit.")
      },
      {
         N_("Exotic Animals"),
         N_("Several exotic animal species being trafficked from all around the galaxy.")
      },
      {
         N_("Radioactive Materials"),
         N_("Highly dangerous, yet highly useful, radioactive materials being sold on the black market, outside of regulatory bodies.")
      },
   }
   cargo = cargoes[rnd.rnd(1, #cargoes)]
   cargo["__save"] = true

   -- mission generics
   stuperpx = 0.3 - 0.015*tier
   stuperjump = 15000
   stupertakeoff = 15000
   timelimit = time.get() + time.create(0, 0,
            traveldist*stuperpx + numjumps*stuperjump + stupertakeoff
               + 480*numjumps)

   -- Allow extra time for refuelling stops.
   local jumpsperstop = 3
   if numjumps > jumpsperstop then
      timelimit:add(time.create(
               0, 0, math.floor((numjumps-1) / jumpsperstop) * stuperjump))
   end
   
   -- Choose amount of cargo and mission reward. This depends on the mission tier.
   finished_mod = 2.0 -- Modifier that should tend towards 1.0 as Naev is finished as a game
   amount = rnd.rnd(10 + 3 * tier, 20 + 4 * tier)
   jumpreward = 3000
   distreward = 0.60
   reward = 1.1^tier * (numjumps*jumpreward + traveldist*distreward)
         * finished_mod * (1. + 0.05*rnd.twosigma())
   
   local title = n_(
         "PIRACY: Illegal Cargo: {amount} t to {planet} ({system} system)",
         "PIRACY: Illegal Cargo: {amount} t to {planet} ({system} system)",
         amount)
   misn.setTitle(fmt.f(title,
         {planet=destplanet:name(), system=destsys:name(),
            amount=fmt.number(amount)}))
   misn.markerAdd(destsys, "computer")
   cargo_setDesc(
         fmt.f(misn_desc, {planet=destplanet:name(), system=destsys:name()}),
         cargo[1], amount, destplanet, numjumps, timelimit)
   misn.setReward(fmt.credits(reward))
end

-- Mission is accepted
function accept()
   if player.pilot():cargoFree() < amount then
      local required_text = n_(
            "You don't have enough cargo space to accept this mission. It requires {required} tonne of free space. ",
            "You don't have enough cargo space to accept this mission. It requires {required} tonnes of free space. ",
            amount)
      local shortfall = amount - player.pilot():cargoFree()
      local shortfall_text = n_(
            "You need {shortfall} more tonne of empty space.",
            "You need {shortfall} more tonnes of empty space.",
            shortfall)
      tk.msg("", fmt.f(required_text .. shortfall_text,
            {required=fmt.number(amount),
               shortfall=fmt.number(shortfall)}))
      misn.finish()
   end
   player.pilot():cargoAdd("Food", amount)
   local playerbest = cargoGetTransit(timelimit, numjumps, traveldist)
   player.pilot():cargoRm("Food", amount)
   if timelimit < playerbest then
      local tlimit = timelimit - time.get()
      local tmore = playerbest - time.get()
      if not tk.yesno("", fmt.f(
               _("This shipment must arrive within {timelimit}, but it will take at least {time} for your ship to reach {planet}, missing the deadline. Accept the mission anyway?"),
               {timelimit=tlimit:str(), time=tmore:str(),
                  planet=destplanet:name()})) then
         misn.finish()
      end
   elseif system.cur():jumpDist(destsys, true, true) == nil
         or system.cur():jumpDist(destsys, true, true) > numjumps then
      local text = n_(
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jump may cause you to miss the deadline. Accept the mission anyway?",
            "The fastest route to {planet} is not currently known to you. Landing to buy maps, spending time searching for unknown jumps, or taking a route longer than {jumps} jumps may cause you to miss the deadline. Accept the mission anyway?",
            numjumps)
      if not tk.yesno("", fmt.f(text,
               {planet=destplanet:name(), jumps=numjumps})) then
         misn.finish()
      end
   end

   misn.accept()

   local cobj = misn.cargoNew(cargo[1], cargo[2])
   carg_id = misn.cargoAdd(cobj, amount)

   local osd_msg = {}
   osd_msg[1] = fmt.f(osd_msg1,
         {planet=destplanet:name(), system=destsys:name(),
            deadline=timelimit:str(), time=(timelimit - time.get()):str()})
   misn.osdCreate(osd_title, osd_msg)
   hook.land("land") -- only hook after accepting
   hook.date(time.create(0, 0, 100), "tick") -- 100STU per tick
end

-- Land hook
function land()
   if planet.cur() == destplanet then
      local cargo_land = {
         _("The containers of {cargotype} are unloaded at the docks."),
         _("The containers of {cargotype} are taken off your hands. The workers shoot you a knowing grin."),
         _("The containers of {cargotype} are unloaded by a group of workers that seem to have no clue what they just took out of your ship."),
      }

      tk.msg("", fmt.f(cargo_land[rnd.rnd(1, #cargo_land)],
               {cargotype=_(cargo[1])}))
      player.pay(reward)
      n = var.peek("ps_misn")
      if n ~= nil then
         var.push("ps_misn", n+1)
      else
         var.push("ps_misn", 1)
      end

      -- increase faction
      if player.misnActive("Fake ID") then
         -- Won't get immediately noticed with fake ID.
         faction.modPlayerSingle("Pirate", 1)
      else
         faction.modPlayer("Pirate", 1)
      end
      misn.finish(true)
   end
end

-- Date hook
function tick()
   if timelimit >= time.get() then
      -- Case still in time
      local osd_msg = {}
      osd_msg[1] = fmt.f(osd_msg1,
            {planet=destplanet:name(), system=destsys:name(),
               deadline=timelimit:str(), time=(timelimit - time.get()):str()})
      misn.osdCreate(osd_title, osd_msg)
   elseif timelimit <= time.get() then
      -- Case missed deadline
      player.msg(msg_timeup)
      misn.finish(false)
   end
end
