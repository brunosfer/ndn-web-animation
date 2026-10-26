# Metrics of the NDN Strategy Lab

The Lab measures every run in three tiers. **Raw metrics** are what the simulator counts directly. **Composed metrics** are computed from raw ones, per consumer and per disruption. **Key indicators** summarise a whole run, so strategies and routing can be compared at a glance. Every value below is computed by the page itself (`web/index.html`) and also returned by the headless runs of the self-test (`tests/selftest.sh`, fields `recovery` and `indicators` of each run).

## Raw metrics

| Where on the page | Metric |
|---|---|
| Network card | Interest, Data, Nack and NLSR (hello, sync, LSA) frames on the medium; air time used by NDN and NLSR frames, idle time and time still queued for the medium; frames lost on a link, into a broken link, dropped by a radio that is off or by a full queue; duplicate Interests and duplicate or unsolicited Data; frames overheard and discarded; Content Store hits per node |
| Producer and consumer cards | per application: Interests received, Data served by the application or a cache, Nacks; readings, frames, pings or segments requested, received from a producer or a cache, late, lost, waiting; retransmissions, delays, goodput |
| Transmission efficiency, per node | Interests and Data sent and received, Nacks, retransmissions suppressed, duplicates, frames lost, queue drops, overheard frames, Content Store hits, NLSR frames |
| Timeline | the outcome of every reading, frame or ping (producer, cache, late, lost) and the throughput of a file |

A request counts as **satisfied** when a reading or ping is answered, a stream frame is complete before its playout time, or a file segment is received. It is satisfied **on the first try** when it needed no retransmission.

## Composed metrics

**Transmission efficiency** (whole run): Interest and Data frames per Data received; Interest efficiency, the minimum Interest frames (one per hop on the shortest path to the node that served each Data, with the links in range at that moment) divided by the Interest frames sent; the share of duplicates and of frames lost.

**After a disruption**, per consumer that was running. A disruption is a change that can cost consumers data:

* a link out of range or made lossy, a radio switched off, a cache switched off or a producer that disconnects, scripted by a profile or made by hand;
* a FIB emptied or a node reset by hand;
* a link that flips out of range, only when the flip cuts an exchange under way over it, that is when either end has an Interest forwarded across the link whose Data has not come back. A flip while the link carries nothing is not a disruption.

| Metric | Definition |
|---|---|
| Satisfaction ratio | In 2 s windows, the share of the requests first sent in the window that were satisfied; for a file, the segments received in the window |
| Steady level | The mean satisfaction ratio over the shorter of 60 s and the time the consumer ran before the disruption |
| Recovery time | From the disruption to the start of the first window from which the ratio stays within 10 % of the steady level for 10 s (or until the consumer has no more data); 0 when it never falls below; "not recovered" if the run ends first |
| Recovery time on time | The same, counting only requests satisfied on the first try. A consumer whose requests all need a retransmission (Best Route blind to a broken link) has not recovered on time, although every request is satisfied |
| Recovery effort | The frames and the air time of the whole network during the recovery time, beyond the network's rate before the disruption (over the same window as the steady level); never below 0 |
| Data gap | From the last Data the consumer received before the disruption to the first Data of a request it sent after it |
| Reaction time | From the disruption until a request sent after it is satisfied on its first try over a path that avoids the failed element (the link, node, producer or cache): the strategy has stopped using the lost path. Data that returns over the restored element (a link back in range, a producer that reconnects) is not a reaction. "Unaffected": the consumer's last path before the disruption did not use the element. Not applicable to a FIB emptied or a node reset |

Requests count by the time they were first sent, and consumers keep retrying for a few seconds, so a consumer can show recovery slightly before the cause ends (24 s for a 30 s producer outage, 30 s on time).

## Key indicators

| Indicator | Definition |
|---|---|
| Delivery | Share of the decided requests that were satisfied |
| Timeliness | Share satisfied on the first try |
| Cost | Frames on the medium, NLSR included, per satisfied request |
| Resilience | Disruption and consumer pairs that recovered, of those with a steady level, and their mean recovery time |
| Resilience on time | The same with the recovery time on time |
| Reaction | Affected disruption and consumer pairs whose strategy found another path, and their mean reaction time |

## Examples

Without NLSR unless stated, from the self-test of version 1.3:

| Profile | Delivery | Timeliness | Cost | Resilience | On time | Reaction |
|---|---|---|---|---|---|---|
| [Reference] No failures, Best Route | 100 % | 100 % | 5.0 | – | – | – |
| [Best Route] Blind to a broken link | 100 % | 54 % | 7.3 | 2 of 2 | 1 of 2 | none |
| [Best Route] Blind to a broken link, with NLSR | | | | | | 1 of 1, 29.3 s |
| [Producers] Two producers, Best Route | 50 % | 50 % | 43.0 | 0 of 2 | 0 of 2 | none |
| [Producers] Two producers, ASF | 100 % | 99 % | 7.4 | 2 of 2 | 2 of 2 | 1 of 1, 0.3 s |
| [Self-Learning] The producer disconnects | 74 % | 68 % | 1,834 | 2 of 2, 24 s | 2 of 2, 30 s | none (data returns only with the producer) |
| [Self-Learning] Stale learned route | | | | | | 1 of 1, 591 s (the route's lifetime) |
