# User Preferences

## Python3 path
when usiing python, search the .venv python in the current project folder and if it exists, use it. If not, use the python of this version -> /usr/bin/python3

## Plotting / Visualization
- Always use **English** for all text in plots (titles, axis labels, legends, annotations, textboxes).
  Reason: the system matplotlib font (DejaVu Sans) does not support CJK glyphs, causing missing-glyph warnings and blank characters in saved figures.

## Waiting on background jobs
- Don't poll for a background job by spawning a `while kill -0 $(pgrep -f "<name>") ...; do sleep N; done` loop:
  `pgrep -f` also matches the waiter shell's own command line (which contains `<name>`), so the loop never sees the
  real job exit and spins forever, leaving zombie waiter + sleep processes.
- Instead rely on the harness's background-task completion notification (run the job with run_in_background and wait
  for the `<task-notification>`), or read the job's output file directly. If you must poll a PID, capture the real
  PID at launch (`$!`) rather than re-deriving it with `pgrep -f`.


- 使用者用什麼語言就用那個語言回覆
