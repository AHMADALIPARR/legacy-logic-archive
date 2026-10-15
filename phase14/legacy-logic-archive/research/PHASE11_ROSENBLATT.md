# Phase 11 — Rosenblatt Mark I Perceptron

## Evidence-backed inventory
- Sensory: 20 x 20 photoresistors = 400 inputs.
- Association: 512 units, random fixed S-to-A plugboard connections.
- Response: 8 units with adjustable thresholds.
- Learning memory: 512 motor-driven potentiometers; wiper positions encode adjustable strengths.
- Training: reinforcement modifies potentiometer settings via motor drive.
- Original IBM 704 simulation preceded dedicated hardware.

## Verification boundaries
These figures describe a documented configuration of Mark I, not every perceptron architecture. No original circuit netlists, IBM 704 programs, or full wire maps have been recovered here. Never label a generated model an original artifact.

## Archive tasks
1. Locate and rights-review AD0236965 operators manual and AD0256582 report.
2. Extract card and plugboard mapping, motor drive limits, response thresholds and calibration procedures from original pages.
3. Produce a traceable pin-level wiring inventory and versioned reconstruction.
4. Build a deterministic simulator with explicit 400x512 sparse connectivity and 512 adjustable analog weights.
5. Verify behavior against original manual test cases before proposing physical hardware.
