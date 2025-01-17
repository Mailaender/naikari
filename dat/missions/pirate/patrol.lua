--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Pirate Patrol">
 <avail>
  <priority>48</priority>
  <chance>560</chance>
  <location>Computer</location>
  <faction>Pirate</faction>
 </avail>
</mission>
--]]
--[[

   Pirate Patrol

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.

--

   Pirate version of the patrol mission.

--]]

require "missions/neutral/patrol"

pay_text = {}
pay_text[1] = _("The crime boss grins and hands you your pay.")
pay_text[2] = _("The local crime boss pays what you were promised, though not before trying (and failing) to pick your pocket.")
pay_text[3] = _("You are hit in the face with something and glare in the direction it came from, only to see the crime boss waving at you. When you look down, you see that it is your agreed-upon payment, so you take it and let out a grin.")
pay_text[4] = _("You are handed your pay in what seems to be a million different credit chips by the crime boss, but sure enough, it adds up to exactly the amount promised.")

abandon_text = {}
abandon_text[1] = _("You are sent a message informing you that landing in the middle of the job is considered to be abandonment. As such, your contract is void and you will not receive payment.")


-- Mission details
misn_title  = _("PIRACY: Patrol of the %s system")
misn_desc   = _("A local crime boss has offered a job to patrol the %s system in an effort to keep outsiders from discovering this Pirate stronghold. You will be tasked with checking various points and eliminating any outsiders along the way.")

-- Messages
secure_msg = _("Point secure.")
hostiles_msg = _("Outsiders detected. Eliminate all outsiders.")
continue_msg = _("Outsiders eliminated.")
done_msg = _("Patrol complete. You can now collect your pay.")
late_msg = _("MISSION FAILURE! You showed up too late.")
abandoned_msg = _("MISSION FAILURE! You have left the %s system.")

osd_title  = _("Patrol")
osd_msg    = {}
osd_msg[1] = _("Fly to the %s system")
osd_msg[2] = "(null)"
osd_msg[3] = _("Eliminate outsiders")
osd_msg[4] = _("Land in %s territory to collect your pay")
osd_msg["__save"] = true

mark_name = _("Patrol Point")


use_hidden_jumps = true

