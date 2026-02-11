-- @patterns:
--   - pattern: That doesn't seem to be either a commodity group, or the name of a planet!
--     type: substring
--   - pattern: I don't seem to recognise that planet name!
--     type: substring

if f2t_po.phase ~= "idle" then
    f2t_debug_log("[po] Invalid planet error during phase: %s", f2t_po.phase)
    deleteLine()
    f2t_po_capture_abort("Planet name not recognized")
end
