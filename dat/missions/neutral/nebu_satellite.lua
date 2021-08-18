--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Nebula Satellite">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>29</priority>
  <chance>10</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
 </avail>
</mission>
--]]
--[[

   Nebula Satellite

   One-shot mission

   Help some independent scientists put a satellite in the nebula.

]]--

require "numstring"
require "missions/neutral/common"


bar_desc = _("A bunch of scientists seem to be chattering nervously among themselves.")
mtitle = _("Nebula Satellite")
mdesc = {}
mdesc[1] = _("Fly to the %s system and wait for the probe to launch")
mdesc[2] = _("Land on %s (%s system) to drop off the scientists")

text = {}
text[1] = _([[You approach the scientists. They seem a bit nervous and one mutters something about whether it's a good idea or not. Eventually one of them comes up to you.

"Hello Captain, we're looking for a ship to take us into the Sol Nebula. Would you be willing to take us there?"]])
text[2] = _([["We had a trip scheduled with a space trader ship, but they backed out at the last minute. So we were stuck here until you came. We've got a research probe that we have to release into the %s system to monitor the Nebula's growth rate. The probe launch procedure is pretty straightforward and shouldn't have any complications."

He takes a deep breath, "We hope to be able to find out more secrets of the Sol Nebula so mankind can once again regain its lost patrimony. So far the radiation and volatility of the deeper areas haven't been very kind to our instruments. That's why we designed this satellite we're going to launch."]])
text[3] = _([["The plan is for you to take us to %s so we can launch the probe, and then return us to our home at %s in the %s system. The probe will automatically send us the data we need if all goes well. You'll be paid %s when we arrive."]])
text[4] = _([[The scientists thank you for your help before going back to their home to continue their nebula research.]])
text[9] = _([["You do not have enough free cargo space to accept this mission!"]])

launch = {}
launch[1] = _("Preparing to launch satellite probe...")
launch[2] = _("Launch in 5...")
launch[3] = _("Satellite launch successful!")

articles={}
articles={
   {
      "Generic",
      _("Scientists Launch Research Probe Into Nebula"),
      _("A group of scientists have successfully launched a science probe into the Nebula. The probe was specifically designed to be resistant to the corrosive environment of the Nebula and is supposed to find new clues about the nature of the gas and where it's from."), 
   }
}

log_text = _([[You helped a group of scientists launch a research probe into the Nebula.]])


function create ()
   -- Note: this mission does not make any system claims.
   -- Set up mission variables
   misn_stage = 0
   homeworld, homeworld_sys = planet.getLandable(misn.factions())
   if homeworld == nil then
      misn.finish(false)
   end
   satellite_sys = system.get("Arandon") -- Not too unstable
   credits = 750000

   -- Set stuff up for the spaceport bar
   misn.setNPC(_("Scientists"), "neutral/unique/neil.png", bar_desc)

end


function accept ()
   -- See if rejects mission
   if not tk.yesno("", text[1]) then
      misn.finish()
   end

   -- Check for cargo space
   if player.pilot():cargoFree() <  3 then
      tk.msg("", text[9])
      misn.finish()
   end

   -- Add cargo
   local c = misn.cargoNew(N_("Satellite"), N_("A small satellite loaded with sensors for exploring the depths of the nebula."))
   cargo = misn.cargoAdd(c, 3)

   -- Set up mission information
   misn.setTitle(mtitle)
   misn.setReward(creditstring(credits))
   misn.setDesc(string.format(mdesc[1], satellite_sys:name()))
   misn_marker = misn.markerAdd(satellite_sys, "low")

   -- Add mission
   misn.accept()

   -- More flavour text
   tk.msg("", string.format(text[2], satellite_sys:name()))
   tk.msg("", string.format(text[3], satellite_sys:name(),
         homeworld:name(), homeworld_sys:name(), creditstring(credits)))

   misn.osdCreate(mtitle, {mdesc[1]:format(satellite_sys:name())})
   -- Set up hooks
   hook.land("land")
   hook.enter("jumpin")
end


function land ()
   landed = planet.cur()
   -- Mission success
   if misn_stage == 1 and landed == homeworld then
      tk.msg("", text[4])
      player.pay(credits)
      addMiscLog(log_text)
      misn.finish(true)
   end
end


function jumpin ()
   sys = system.cur()
   -- Launch satellite
   if misn_stage == 0 and sys == satellite_sys then
      hook.timer(3, "beginLaunch")
   end
end

--[[
   Launch process
--]]
function beginLaunch ()
   player.msg(launch[1])
   misn.osdDestroy()
   hook.timer(3, "beginCountdown")
end
function beginCountdown ()
   countdown = 5
   player.msg(launch[2])
   hook.timer(1, "countLaunch")
end
function countLaunch ()
   countdown = countdown - 1
   if countdown <= 0 then
      launchSatellite()
   else
      player.msg(string.format(_("%d..."), countdown))
      hook.timer(1, "countLaunch")
   end
end
function launchSatellite ()

   articles[1][4] = time.get() + time.create(0,3,0)
   news.add(articles)


   misn_stage = 1
   player.msg(launch[3])
   misn.cargoJet(cargo)
   misn.setDesc(mdesc[2]:format(homeworld:name(), homeworld_sys:name()))
   misn.osdCreate(mtitle,
         {mdesc[2]:format(homeworld:name(), homeworld_sys:name())})
   misn.markerMove(misn_marker, homeworld_sys)
end
