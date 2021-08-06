--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Shipwreck">
 <trigger>enter</trigger>
 <chance>3</chance>
 <cond>system.cur():presence("Pirate") &gt; 0 and not player.misnDone("The Space Family") and not player.misnActive("The Space Family")</cond>
 <flags>
  <unique />
 </flags>
</event>
--]]
--[[
-- Shipwreck Event
-- 
-- Creates a wrecked ship that asks for help. If the player boards it, the event switches to the Space Family mission.
-- See dat/missions/neutral/spacefamily
-- 
-- 12/02/2010 - Added visibility/highlight options for use in big systems (Anatolis)
--]]

-- Text
broadcastmsg = _("SOS. This is %s. We are shipwrecked. Please #bboard#0 us by positioning your ship over ours and then #bdouble-clicking#0 on our ship.")
shipname = _("August") --The ship will have a unique name
shipwreck = _("Shipwrecked %s")

function create ()
    local nebu_dens, nebu_vol = system.cur():nebula()
    if nebu_vol > 0 then
        evt.finish()
    end

    -- The shipwreck will be a random trader vessel.
    r = rnd.rnd()
    if r > 0.8 then
        ship = "Mule"
    elseif r > 0.5 then
        ship = "Koala"
    else 
        ship = "Llama"
    end

    -- Create the derelict.
    angle = rnd.rnd() * 2 * math.pi
    dist = rnd.rnd(2000, 3000) -- place it a ways out
    pos = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
    p = pilot.add(ship, "Derelict", pos, shipwreck:format(shipname),
            {ai="dummy"})
    p:disable()
    p:rename(shipwreck:format(shipname))
    -- Added extra visibility for big systems (A.)
    p:setVisplayer(true)
    p:setHilight(true)

    hook.timer(3, "broadcast")

    -- Set hooks
    hook.pilot(p, "board", "rescue")
    hook.pilot(p, "death", "destroyevent")
    hook.enter("endevent")
    hook.land("endevent")
end

function broadcast ()
    -- Ship broadcasts an SOS every 10 seconds, until boarded or destroyed.
    if not p:exists() then
        return
    end
    p:broadcast(string.format(broadcastmsg, shipname), true)
    bctimer = hook.timer(15, "broadcast")
end

function rescue ()
    -- Player boards the shipwreck and rescues the crew, this spawns a new mission.
    hook.rm(bctimer)
    naev.missionStart("The Space Family")
    evt.finish()
end

function destroyevent ()
    evt.finish(true)
end

function endevent ()
    evt.finish()
end
