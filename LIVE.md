# LIVE (railway-openmuse)

| kind | id/code | status |
|---|---|---|
| template | **`openmuse`** / id bfe67c31-595a-4a32-9cce-88ab91344d80 | PUBLISHED 2026-09-22 as "OpenMuse" |

Published 2026-10-03 (UTC 10-04 00:54): image `ghcr.io/will-bogusz/openmuse:fed01e9-20261003@sha256:46323e298ee48a3ad0e4d19fbd3df0e5aeee2c3d3f5b36737178f0da64ce586a` (Caddy/API restarted in place), `CPK_INTELLIGENCE_API_KEY` and `MODEL` descriptions, README (first-use steps). Public API readback equal to `template/serializedConfig.json`; README byte-equal. Fresh deploy with a project key and an OpenRouter-backed model (deployment 402be831-fed9-48c5-a8e4-910578e237e1): all three services SUCCESS in 46 s, deployed image matches, `/api/health` 200, `/api/session` correct access key 200 / wrong 401, `/api/workspace` 401 without and 200 with the session token; project deleted. Previous image `fed01e9-20260922@sha256:67063ca1…`.

## 2026-10-03 presentation rework (live)

- README opening block (banner `openmuse-banner-v1.png`, one-line benefit, three first-use steps with plan/cost) published and read back byte-identical from the public API; displaced plan/first-run text moved into Implementation Details.
- Icon: openmuse-icon-v2.png (512 px, 74 KB; was 1.4 MB). Description: unchanged.
- Banner captured from a throwaway `kit-*-banner` deploy of the live template (deleted). Evidence: ~/tmp/adhoc/2026-10-03-template-status/presentation/stage-b/.
