--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="The macho teenager">
 <flags>
  <unique />
 </flags>
 <avail>
  <priority>20</priority>
  <chance>5</chance>
  <location>Bar</location>
  <faction>Dvaered</faction>
  <faction>Empire</faction>
  <faction>Goddard</faction>
  <faction>Independent</faction>
  <faction>Sirius</faction>
  <cond>player.numOutfit("Mercenary License") &gt; 0 and planet.cur():class() ~= "0" and planet.cur():class() ~= "1" and planet.cur():class() ~= "2" and planet.cur():class() ~= "3"</cond>
 </avail>
</mission>
--]]
--[[
--
-- MISSION: The macho teenager
-- DESCRIPTION: A man tells you that his son has taken one of his yachts without permission and
-- is joyriding it with his girlfriend to impress her. Disable the yacht and board it, then take
-- the couple back to the planet (destroying the yacht incurs a penalty)
--
--]]

-- Localization, choosing a language if Naev is translated for non-english-speaking locales.

local fmt = require "fmt"
require "events/tutorial/tutorial_common"


ask_text = _([["Excuse me," the man says as you approach him. "I'm looking for a capable pilot to resolve a small matter for me. Perhaps you can help me? You see, it's my son. He's taken my yacht to space without my permission, taking along his girlfriend. That boy is such a handful. I'm sure he's trying to show off his piloting skills to impress her. I need you to get out there, disable the yacht and take them both back here. Can you do this for me? I'll make it worth your while."]])

yes_text = _([["Thank you! The yacht doesn't have a working hyperdrive, so they won't have left the system. It's a Gawain named Credence. Just disable it and board it, then transport my disobedient son and his girlfriend back here. Don't worry about the yacht, I'll have it recovered later. Oh, and one more thing, though it should go without saying: whatever you do, don't destroy the yacht! I don't want to lose my son over this. Well then, I hope to see you again soon."]])

fail_text = _([[The Credence has been destroyed! You resolve to get out of here as soon as possible so the father doesn't do something to you.]])

board_text = _([[You board the Gawain and find an enraged teenage boy and a disillusioned teenage girl. The boy is furious that you attacked and disabled his ship, but when you mention that his father is quite upset and wants him to come home right now, he quickly pipes down. You march the young couple onto your ship and seal the airlock behind you.]])

pay_text = _([[The boy's father awaits you at the spaceport. He gives his son and the young lady a stern look and curtly commands them to wait for him in the spaceport hall. The couple droops off, and the father turns to face you.

"You've done me a service, captain," he says. "As promised, I have a reward for a job well done. You'll find it in your bank account. I'm going to give my son a reprimand he'll not soon forget, so hopefully he won't repeat this little stunt anytime soon. Well then, I must be going. Thank you again, and good luck on your travels."]])

btutorial_text = _([[As you exit the atmosphere to search for the joyriding teenager, Ian Structure shows up on your screen once again. "I saw your mission log. Those teenagers sure can be a bother! Anyhow, you're going to need to disable and #bboard#0 the Credence to capture him, so please let me explain that real quick.

"To board a ship, you must use disabling weapons, such as ion cannons, to disable what you want to board. There are some missions and events that allow you to board certain ships without disabling them, but this isn't one of them, so I hope you have some good ion cannons or Medusa missiles! Anyway, once a ship is disabled or otherwise can be boarded, you can do so by either #bdouble-clicking#0 on it, or targeting it with {target_key} and then pressing {board_key}. In most cases, boarding lets you steal the ship's credits, cargo, ammo, and/or fuel, but sometimes, like in this mission, it can trigger special mission events instead (in this case, boarding the Credence will allow you to capture the troublesome teenagers).

"Good luck on your mission!"]])

NPCname = _("A middle-aged man")
NPCdesc = _("You see a middle-aged man, who appears to be one of the locals, looking around the bar, apparently in search of a suitable pilot.")

misndesc = _("A disgruntled parent has asked you to fetch his son and his son's girlfriend, who have taken a yacht and are joyriding it in the {system} system.")
misnreward = _("300 k¢")

OSDtitle = _("The macho teenager")
OSD = {}
OSD[1] = _("Fly to the {system} system")
OSD[2] = _("Disable and board Gawain Credence")
OSD[3] = _("Land on {planet} ({system} system)")


function create ()
    cursys = system.cur()
    curplanet = planet.cur()

    if not misn.claim(cursys) then
        misn.finish(false)
    end

    misn.setNPC(NPCname, "neutral/unique/middleaged.png", NPCdesc)
end


function accept ()
    if tk.yesno("", ask_text) then
        misn.accept()

        misn.setTitle(OSDtitle)
        misn.setDesc(fmt.f(misndesc, {system=cursys:name()}))
        misn.setReward(misnreward)

        OSD[1] = fmt.f(OSD[1], {system=cursys:name()})
        OSD[3] = fmt.f(OSD[3], {planet=curplanet:name(), system=cursys:name()})
        misn.osdCreate(OSDtitle, OSD)

        tk.msg("", yes_text)

        hook.enter("enter")

        targetlive = true
    else
        misn.finish()
    end
end

function enter()
    if not targetlive then
        return
    end

    if system.cur() == cursys then
        misn.osdActive(2)

        tutExplainBoarding(fmt.f(btutorial_text,
                {target_key=tutGetKey("target_next"),
                    board_key=tutGetKey("board")}))

        local dist = rnd.rnd() * system.cur():radius()
        local angle = rnd.rnd() * 2 * math.pi
        local location = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
        target = pilot.add("Gawain", "Civilian", location, _("Credence"))
        target:control()
        target:memory().aggressive = true
        target:setHilight(true)
        target:setVisplayer(true)

        hidle = hook.pilot(target, "idle", "targetIdle")
        hook.pilot(target, "exploded", "targetExploded")
        hook.pilot(target, "board", "targetBoard")
        targetIdle()
    else
        misn.osdActive(1)
    end
end

function targetIdle()
    if not target:exists() then
        hook.rm(hidle)
        return
    end
    local location = target:pos()
    local dist = 750
    local angle = rnd.rnd() * 2 * math.pi
    local newlocation = vec2.new(dist * math.cos(angle), dist * math.sin(angle))
    target:taskClear()
    target:moveto(location + newlocation, false, false)
    hook.timer(5.0, "targetIdle")
end

function targetExploded()
    hook.timer(2.0, "targetDeath")
end

function targetDeath()
    if not targetlive then
        return
    end
    tk.msg("", fail_text)
    misn.finish(false)
end

function targetBoard()
    player.unboard()

    tk.msg("", board_text)

    target:setHilight(false)
    target:setVisplayer(false)
    target:disable()

    local c = misn.cargoNew(N_("Teenagers"), N_("Disillusioned teenagers."))
    cargoID = misn.cargoAdd(c,0)

    targetlive = false
    misn.osdActive(3)

    hook.land("land")
end

function land()
    if planet.cur() == curplanet and not targetlive then
        tk.msg("", pay_text)
        player.pay(300000) -- 300K
        misn.finish(true)
    end
end

function abort ()
    if target then
        target:control(false)
        target:setHilight(false)
        target:setVisplayer(false)
    end
    misn.finish(false)
end
