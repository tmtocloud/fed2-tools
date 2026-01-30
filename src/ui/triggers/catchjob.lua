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
ui_job_time  = matches[5]      --how long do you have to deliver it
ui_job_pay   = matches[6] * 75  --how much per ton you're paid * 75 tons of cargo

ui_locations = {origin, destination}  --put the two planets in one location
table.sort(ui_locations)                        --alphabetize them
ui_locations = table.concat(ui_locations)   --smush the alphabetized planets together

-- If out of Sol, dont try to calculate gtu
if gmcp.room.info.system == "Sol" then
  ui_calcTime = ui_sol_distances[ui_locations] --use that to get the actual time between origin and destination

  if tonumber(ui_job_distance) > tonumber(ui_job_time) then      --you don't have enough time to deliver without penalties
    --we're just not gonna do anything here
  elseif tonumber(ui_job_distance) < tonumber(ui_job_time) then  --you can deliver faster than allocated time and may receive bonuses
    ui_hauling_window:cechoLink("<blue><u>" .. job_number .. "</u><reset>",function() send("ac " .. job_number) end, "Accept job " .. job_number, true)
    ui_hauling_window:cecho(" <ansiCyan>"..rpad(origin,8).."<reset> > <ansiCyan>"..rpad(destination,8)..
    "<reset> <b>"..ui_job_time.."/<ansiGreen>"..ui_job_distance.."<reset>gtu - <b>"
    ..ui_job_pay.."</b>ig (<b><ansiGreen>".. math.floor(ui_job_pay+(ui_job_pay*.2)) .."<reset></b>ig)\n")
  else --
    ui_hauling_window:cecho(job_number.." <ansiCyan>"..rpad(origin,8).."<reset> > <ansiCyan>"..rpad(destination,8)..
    "<reset> <b>"..ui_job_time.."/"..ui_job_distance.."</b>gtu - <b>"..ui_job_pay.."</b>ig\n")
  end
else
  ui_hauling_window:cechoLink("<blue><u>" .. job_number .. "</u><reset>",function() send("ac " .. job_number) end, "Accept job " .. job_number, true)
  ui_hauling_window:cechoLink(" <ansiCyan>" .. rpad(origin,13).."<reset>",function() send("whereis " .. origin) end, "Find " .. origin, true)
  ui_hauling_window:cecho(" > ")
  ui_hauling_window:cechoLink("<ansiCyan>" .. rpad(destination,13) .. "<reset>",function() send("whereis " .. destination) end, "Find " .. destination, true)
  ui_hauling_window:cecho(" <b>" .. ui_job_time .. "</b>gtu - <b>" .. ui_job_pay .. "</b>ig\n")
end
deleteLine()