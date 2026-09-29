# AUREN Production Worker

Server-side worker contract for long-form video production.

The worker polls/receives production jobs, expands a Story Bible into scenes/shots, routes each shot to a configured provider adapter, assembles approved media, and reports progress back to AUREN.

This repository intentionally contains provider-neutral adapters. API keys and GPU infrastructure are environment configuration, never committed to Git.

Pipeline:
queue -> planning -> shot generation -> voice/music -> assembly -> review -> output

Production targets:
- Shorts: MoneyPrinterTurbo adapter
- Films: SkyReels/LTX/Wan/Hunyuan adapters
- Series: same long-form pipeline, episode-scoped jobs

The worker must never claim a job completed until an output artifact has been successfully written and verified.
