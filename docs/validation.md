# How close the NDN Strategy Lab is to Mini-NDN-WiFi

This page summarises why the NDN Strategy Lab exists and how faithfully it reproduces the emulated NDN stack it was built from: Mini-NDN with NFD, NLSR and ndn-tools on Mininet-WiFi, where `mac80211_hwsim` and `wmediumd` emulate the radios.

## Why we built it

**To test strategy concepts early, quickly and without noise.** Emulation runs the real forwarder and is the right place to evaluate a finished strategy, but for an early concept it is costly. Every run takes real time, its outcome varies with the host's CPU scheduling, and individual frames and table entries are hard to inspect. That variance hides the effect of a design change, and the run time limits how many ideas can be tried. The Lab reproduces the emulator's behaviour in a deterministic discrete-event model, across the features and options a strategy study needs: four strategies, static routes, NLSR or none, sensor, file, stream and ping traffic, lossy, broken and flipping links, and producers that leave. A concept can then be explored in seconds and reaches Mini-NDN on Mininet-WiFi with `wmediumd` already checked, without large surprises or complete failures.

**To lower the barrier to NDN.** In our experience NDN asks for a change of mindset and has a steep learning curve. A simple visual tool, where every Interest, Data, table and timer can be watched, helps newcomers understand it and, we hope, encourages the community.

## What this repository is

This is the standalone web version: one page, no backend, no installation. It is a snapshot of a private repository where development continues. The next step there separates the page into a front end and a back end, whose engine stays simple: tables and the forwarding rules reproduced from the experiments below. That is our path towards implementing the new strategy in Mini-NDN on Mininet-WiFi and `wmediumd` and measuring it against the existing strategies.

## How it was checked

| | |
|---|---|
| Reference stack | Linux 6.8 (`mac80211_hwsim`), Mininet-WiFi 2.7, `wmediumd` 0.5, Mini-NDN 0.7.0, NFD 24.07, NLSR 24.08 with PSync 0.5.0, ndn-cxx 0.9.0, ndn-tools 24.07 |
| Host | one VirtualBox VM on a laptop (AMD Ryzen 5 PRO 5650U), 2 vCPUs and 8 GB, then 4 vCPUs and 12 GB; results of the two sizes are kept apart |
| Topology | the Lab's 13 stations and 20 links rebuilt exactly: same addresses, link costs and per-link loss, 802.11g at a fixed 12 Mbit/s, `wmediumd` in error-probability mode, one unicast face per neighbour |
| Applications | ndnping and ndnget from ndn-tools; the sensor and stream applications written in C++ on ndn-cxx with the Lab's behaviour |
| Replay | each scenario runs in the Lab first, which exports its exact settings (applications, strategies, links, events); the emulator replays those settings, so nothing is translated by hand |
| Criteria | 15 criteria in six classes: set-up, timing, medium, routing, strategy and caching |
| Acceptance | counts the Lab claims to reproduce within ±5 %; throughput and timing within ±25 %; emergent behaviours (floods, path choices) when the mechanism and its direction match |
| Campaign | 24 October 2026, three phases, about 7 h 20 min: 75 emulation sessions and 178 Lab runs |
| Repetitions | emulator runs repeated two to four times where outcomes vary; Lab runs with ten seeds where they depend on random draws |
| Run lengths | set by the protocols' timers: NLSR for 30 minutes (one LSA refresh period), a stale route for 700 s (beyond its 10-minute lifetime), 1,000 frames per loss level (±3.1 percentage points at 95 %) |

The whole set of 24 profiles, run with and without NLSR (84 runs, 1 h 49 min of network time), completes in 39 s on the same VM, about 170 times faster than real time and with the same result on every run. The emulator needs the full network time of every run, plus start-up and, with NLSR, 34 s of convergence.

## Results

Of the 36 metrics compared, the Lab is within ±5 % of the emulator's median on 17, within ±25 % on 11 more, and further away on 8, each explained below.

| Class | Metric | Emulator | Lab |
|---|---|---|---|
| Timing | ping round trip over 4 hops, best case | 5.74 ms (2 vCPUs), 7.25 ms (4 vCPUs) | 5.86 ms |
| Medium | tries spent on a lost unicast frame | 9.1–9.3 | 9 |
| Medium | 300 KB file over 4 hops; then from a cache 1 hop away | 1.82–1.99; 6.2–7.6 Mbit/s | 1.70; 8.4 Mbit/s |
| Routing | NLSR packets in 30 minutes | 6,720 | 6,206 |
| Routing | retransmissions after a cut, static routes | 110 | 110 |
| Routing | retransmissions until NLSR repairs the cut | 49, 51 | 25–80 (ten seeds) |
| Routing | link flipping every 9 s, static routes: retransmissions; frames | 147; 3,740 | 147; 3,735 |
| Routing | readings lost to a stale Self-Learning route | 589 of 700 | 588 of 700 |
| Strategy | two producers, the first leaves, Best Route: readings (static; NLSR) | 31; 30 of 60 | 30; 30 of 60 |
| Strategy | two stream viewers, Best Route: packets | 16,344–16,784 | 16,272 |
| Strategy | producer leaves for 30 s, Self-Learning: readings | 64–65 of 90 | 66 of 90 |
| Strategy | low-latency stream after a cut: frames on time at `c1` (Best Route, ASF, Multicast, Self-Learning) | 101, 290, 97, 285 | 97, 300, 124, 298 |
| Caching | small Content Stores: readings; frames | 144 of 150; 11,325 | 140 of 150; 11,228 |

**Where the Lab differs, and why:**

* **Latency.** The Lab's per-hop delay is the emulator's best case. The rest of the emulator's delay comes from the host: a timer on the VM fires 0.47 ms late at the median and 7.2 ms late at the 99th percentile. Absolute delays in the Lab are therefore lower, by design.
* **Choices that depend on timing.** ASF's path ranking, the routes Self-Learning learns and the phase of NLSR's timers vary between emulator runs; the Lab shows one of the observed outcomes. Self-Learning's flood after a producer leaves has the same cause and the same effect on the consumers in both, but the Lab's is larger: about 8,200 frames per second against 1,000–3,500.
* **A file beside a Self-Learning stream.** The Lab's file is slower (0.37 against 0.98 Mbit/s); the stream collapses in both (12 and 11 of 100 frames on time). This difference is still open.
* **Overload.** Above about 7,000 packets per second, for example two Multicast stream viewers, the single-threaded `wmediumd` falls behind and loses frames itself, so emulator results in that regime show only that the medium is overloaded.
* **Not modelled.** Beacons (a few per cent of the airtime), propagation, interference and capture (links are an explicit list), and the cost of signing.

## Versions

* [v0.11](https://github.com/brunosfer/ndn-web-animation/tree/v0.11): first public version; the *Model and sources* table lists every modelled property with its source in NFD, NLSR, ndn-tools or `wmediumd`.
* [v1.0](https://github.com/brunosfer/ndn-web-animation/tree/v1.0): two producers, applications with kinds of data, NLSR sync model.
* [v1.1](https://github.com/brunosfer/ndn-web-animation/tree/v1.1): the corrections from this validation. A lost frame uses the measured rate table of 2 + 3 + 4 tries, there is no radio queue limit by default, and the two-producer profile no longer depends on an equal-cost tie. The *Model and sources* table gains a column, *Checked in Mini-NDN-WiFi*, with the result for each property.
* [v1.2](https://github.com/brunosfer/ndn-web-animation/tree/v1.2): interface changes, not a new validation. The Network card shows the air time of the shared medium (NDN, NLSR, idle and queued), the page shows its version with a link to its source, and an air-time figure that counted queued frames as already sent is corrected.

## A fix in the emulator

The validation exposed a defect in `wmediumd`: its netlink socket overflowed under bursty traffic and dropped frames silently, which halved throughput and hid the Self-Learning flood. It is fixed in [our fork](https://github.com/brunosfer/wmediumd/tree/netlink-socket-overflow). The socket requests an 8 MiB receive buffer with `SO_RCVBUFFORCE`, independent of `net.core.rmem_max`, and no longer asks for acknowledgements. The results above that involve sustained traffic come from the corrected `wmediumd`; the routing scenarios, whose traffic is low, were measured with the original one, which lost at most 25 frames in them.

## Conclusion

On counts that follow from protocol rules the Lab matches the emulator exactly or within a few per cent. It matches throughput within 15–30 %, with one open exception, and it reproduces each strategy's failure mode with the same cause. It is therefore a sound, lightweight first stage for early strategy and routing concepts. Quantitative claims, and anything that depends on timing, still belong in Mini-NDN on Mininet-WiFi.
