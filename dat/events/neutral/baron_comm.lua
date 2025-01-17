--[[
<?xml version='1.0' encoding='utf8'?>
<event name="Baroncomm_baron">
 <trigger>enter</trigger>
 <chance>4</chance>
 <cond>
  not var.peek("baron_hated") and
  not player.misnDone("Baron") and
  not player.misnActive("Baron") and
  (
     system.cur():faction() == faction.get("Empire") or
     system.cur():faction() == faction.get("Dvaered") or
     system.cur():faction() == faction.get("Sirius")
  )
 </cond>
 <flags>
 </flags>
 <notes>
  <campaign>Baron Sauterfeldt</campaign>
 </notes>
</event>
--]]
--[[
-- Comm Event for the Baron mission string
--]]


function create ()
    if not evt.claim(system.cur()) then
        evt.finish(false)
    end

    local lastcomm = var.peek("baroncomm_last")
    if lastcomm == nil then
        var.push("baroncomm_last", time.get():tonumber())
        evt.finish(false)
    else
        if time.get() - time.fromnumber(lastcomm) < time.create(0, 50, 0) then
            evt.finish(false)
        else
            var.push("baroncomm_last", time.get():tonumber())
        end
    end

    hyena = pilot.add("Hyena", "Civilian", true, _("Civilian Hyena"))
    
    hook.pilot(hyena, "jump", "finish")
    hook.pilot(hyena, "death", "finish")
    hook.land("finish")
    hook.jumpout("finish")

    hailie = hook.timer(3.0, "hailme");
end

-- Make the ship hail the player
function hailme()
    hyena:hailPlayer()
    hook.pilot(hyena, "hail", "hail")
end

-- Triggered when the player hails the ship
function hail()
    player.commClose()
    naev.missionStart("Baron")
    evt.finish(true)
end

function finish()
    hook.rm(hailie)
    evt.finish()
end
