# NATS + BEAM static-analysis targets

## NATS
- Protocol parsing and subject wildcard matching
- Authentication: TLS, NKeys, JWT, account isolation
- JetStream persistence, acknowledgements, redelivery, retention
- Cluster routing, leaf nodes, gateways, split-brain and reconnection
- Message ordering, backpressure, request/reply and timeout handling

## Erlang/OTP
- BEAM schedulers and process mailboxes
- gen_server, supervisor, application, gen_statem
- ETS/DETS, distributed Erlang, net_kernel, Mnesia
- Fault recovery and shutdown behavior

## Elixir ecosystem
- Macro expansion, compiler and code loading
- Task, GenServer, DynamicSupervisor, Registry, PartitionSupervisor
- Phoenix channels, LiveView lifecycle, PubSub
- Gnat ConnectionSupervisor/ConsumerSupervisor, JetStream APIs

## Cross-stack verification
- NATS subject -> Elixir consumer -> OTP supervision -> durable event log
- Trace message ID, publisher, consumer, ack, retry and hash
- Evaluate at-most-once/at-least-once claims against actual code paths
- Capture tests and failure modes, never infer correctness from documentation alone
