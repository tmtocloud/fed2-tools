-- @patterns:
--   - pattern: ^\s+\d+\.\s+From\s+.+\s+to\s+.+\s+\-\s+\d+\s+tons of\s+.+\s+\-\s+\d+gtu\s+\d+ig/tn\s+\d+hcr
--     type: regex

-- Capture each job line from work command output
-- Only capture and hide if actively capturing
if f2t_ac_is_capturing() then
    deleteLine()
    f2t_ac_add_job_line(line)

    -- Reset the capture timer since we got new data
    f2t_ac_reset_capture_timer()
end
