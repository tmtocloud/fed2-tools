-- @patterns:
--   - pattern: (\d+)\.\s+(?:From|From The)\s+(.+?)\s+(?:to|to The)\s+(.+?)\s+-\s+.+?\s+-\s+(\d+)gtu\s+(\d+)ig
--     type: regex

local function rpad(str, len)
  str = tostring(str)
  local pad = len - #str
  if pad > 0 then
    return str .. string.rep(" ", pad)
  end
  return str:sub(1, len)
end

--this assumes jobs are provided in lots of 75 tons
--does not capture or display hauling credits per job
-- Job IDs can be clicked on to send the ac JobNum command to FED
-- Planets can be clicked on to send whereis planetName to FED

local job_number   = matches[2]       --what is the job number
local origin = matches[3]     --what planet is the collection point
local destination  = matches[4]      --what planet is the delivery point
UI.job_time  = matches[5]      --how long do you have to deliver it
UI.job_pay   = matches[6] * 75  --how much per ton you're paid * 75 tons of cargo

UI.locations = {origin, destination}  --put the two planets in one location
table.sort(UI.locations)                        --alphabetize them
UI.locations = table.concat(UI.locations)   --smush the alphabetized planets together

-- If out of Sol, dont try to calculate gtu
if gmcp.room.info.system == "Sol" then
  UI.calcTime = UI.sol_distances[UI.locations] --use that to get the actual time between origin and destination

  if tonumber(UI.job_distance) > tonumber(UI.job_time) then      --you don't have enough time to deliver without penalties
    --we're just not gonna do anything here
  elseif tonumber(UI.job_distance) < tonumber(UI.job_time) then  --you can deliver faster than allocated time and may receive bonuses
    UI.hauling_window:cechoLink("<blue><u>" .. job_number .. "</u><reset>",function() send("ac " .. job_number) end, "Accept job " .. job_number, true)
    UI.hauling_window:cecho(" <ansiCyan>"..rpad(origin,8).."<reset> > <ansiCyan>"..rpad(destination,8)..
    "<reset> <b>"..UI.job_time.."/<ansiGreen>"..UI.job_distance.."<reset>gtu - <b>"
    ..UI.job_pay.."</b>ig (<b><ansiGreen>".. math.floor(UI.job_pay+(UI.job_pay*.2)) .."<reset></b>ig)\n")
  else --
    UI.hauling_window:cecho(job_number.." <ansiCyan>"..rpad(origin,8).."<reset> > <ansiCyan>"..rpad(destination,8)..
    "<reset> <b>"..UI.job_time.."/"..UI.job_distance.."</b>gtu - <b>"..UI.job_pay.."</b>ig\n")
  end
else
  UI.hauling_window:cechoLink("<blue><u>" .. job_number .. "</u><reset>",function() send("ac " .. job_number) end, "Accept job " .. job_number, true)
  UI.hauling_window:cechoLink(" <ansiCyan>" .. rpad(origin,13).."<reset>",function() send("whereis " .. origin) end, "Find " .. origin, true)
  UI.hauling_window:cecho(" > ")
  UI.hauling_window:cechoLink("<ansiCyan>" .. rpad(destination,13) .. "<reset>",function() send("whereis " .. destination) end, "Find " .. destination, true)
  UI.hauling_window:cecho(" <b>" .. UI.job_time .. "</b>gtu - <b>" .. UI.job_pay .. "</b>ig\n")
end
deleteLine()