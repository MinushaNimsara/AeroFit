Exercise GIF pipeline (local, no paid API)

1) Put ordered pose frames here:
   scripts/gif_pipeline/frames/<exercise_slug>/01_*.jpg|png
   scripts/gif_pipeline/frames/<exercise_slug>/02_*.jpg|png
   ...

2) Build GIF:
   "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" scripts\make_exercise_gif.py ^
     --frames scripts\gif_pipeline\frames\decline_barbell_bench_press ^
     --out assets\exercises\images\chest\decline_barbell_bench_press.gif ^
     --size 512 --duration 280 --pingpong

3) Point JSON "image" field to the .gif path.

Notes:
- Frame generators often change camera angle between poses; review before shipping.
- Prefer real sourced GIFs when available.
- Do not commit huge batches of AI GIFs without size checks.
