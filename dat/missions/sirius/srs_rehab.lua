--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Sirius Rehabilitation">
 <avail>
  <priority>100</priority>
  <cond>faction.playerStanding("Sirius") &lt; 0</cond>
  <chance>100</chance>
  <location>Computer</location>
 </avail>
</mission>
--]]
--[[
--
-- Rehabilitation Mission
--
--]]

require "missions/rehab_common"

fac = faction.get("Sirius")
