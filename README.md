# otel_gcp_gke

Dartastic OpenTelemetry bridge for GCP GKE (managed Kubernetes).

Wraps each call in a CLIENT-kind span with vendor-specific attributes following OpenTelemetry semantic conventions where applicable.

```dart
import 'package:otel_gcp_gke/otel_gcp_gke.dart';

await tracedGcpGKE<void>(
  operation: 'someOp',
  invoke: () async {
    final r = await client.someOp();
    return GcpGKECallResult(value: r, result: GcpGKEResult(statusCode: 200));
  },
);
```

Suppress instrumentation within a block:

```dart
await runWithoutGcpGKEInstrumentationAsync(() async {
  await client.someInternalSync();
});
```
