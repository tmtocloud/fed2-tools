-- @patterns:
--   - pattern: ^\s+(\d+)\.\s+From\s+(.+?)\s+to\s+(.+?)\s+-\s+\d+\s+tons\s+of\s+\S+\s+-\s+(\d+)gtu\s+(\d+)ig
--     type: regex

onHaulingJob(matches[2], matches[3], matches[4], matches[5], matches[6])
-- deleteLine()