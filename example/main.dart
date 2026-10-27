// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_gcp_gke/otel_gcp_gke.dart';

/// Traces Gcp Gke calls with OpenTelemetry.
///
/// `otel_gcp_gke` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Gcp Gke call in
/// [tracedGcpGKE]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'gcp-gke-example');

  // Traces a Gcp Gke call.
  final gcpGKEId = await tracedGcpGKE<String>(
    operation: 'create',
    invoke: () async {
      // Make the Gcp Gke call here, then report what it returned.
      const id = 'gcp_gke_8f3a2c';
      return const GcpGKECallResult(
          value: id,
          result: GcpGKEResult(
              project: 'example',
              location: 'example',
              clusterName: 'example',
              nodePool: 'example',
              podCount: 3,
              version: '1',
              statusCode: 201,
              errorCode: 'example',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedGcpGKE create returned $gcpGKEId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGcpGKEInstrumentationAsync.
  await runWithoutGcpGKEInstrumentationAsync(
    () => tracedGcpGKE<String>(
      operation: 'create',
      invoke: () async {
        const id = 'gcp_gke_8f3a2c';
        return const GcpGKECallResult(
            value: id,
            result: GcpGKEResult(
                project: 'example',
                location: 'example',
                clusterName: 'example',
                nodePool: 'example',
                podCount: 3,
                version: '1',
                statusCode: 201,
                errorCode: 'example',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
