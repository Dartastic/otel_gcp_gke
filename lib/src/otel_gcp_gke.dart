// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_gcp_gke_suppression.dart';

class GcpGKEResult {
  /// Creates a result.
  const GcpGKEResult({
    this.project,
    this.location,
    this.clusterName,
    this.nodePool,
    this.podCount,
    this.version,
    this.statusCode,
    this.errorCode,
    this.errorMessage,
  });

  final String? project;
  final String? location;
  final String? clusterName;
  final String? nodePool;
  final int? podCount;
  final String? version;
  final int? statusCode;
  final String? errorCode;
  final String? errorMessage;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class GcpGKECallResult<T> {
  /// Creates a call result.
  const GcpGKECallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final GcpGKEResult? result;
}

Future<T> tracedGcpGKE<T>({
  required String operation,
  required Future<GcpGKECallResult<T>> Function() invoke,
  APITracer? tracer,
}) async {
  if (gcpGKEInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTelAPI.tracerProvider().getTracer('otel_gcp_gke');
  final span = t.startSpan('gke $operation', kind: SpanKind.client);
  try {
    span.addAttributes(OTelAPI.attributes(
        [OTelAPI.attributeString('gcp.service', 'container')]));
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.project != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('gcp.project.id', res.project!)]));
      }
      if (res.location != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('cloud.region', res.location!)]));
      }
      if (res.clusterName != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('k8s.cluster.name', res.clusterName!)]));
      }
      if (res.nodePool != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('gcp.gke.node_pool', res.nodePool!)]));
      }
      if (res.podCount != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeInt('k8s.cluster.pod.count', res.podCount!)]));
      }
      if (res.version != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('k8s.cluster.version', res.version!)]));
      }
      if (res.statusCode != null) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeInt('http.response.status_code', res.statusCode!)
        ]));
      }
      if (res.errorCode != null) {
        span.addAttributes(OTelAPI.attributes(
            [OTelAPI.attributeString('gke.error.code', res.errorCode!)]));
      }
      final fail = res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.addAttributes(OTelAPI.attributes([
          OTelAPI.attributeString(
            ErrorAttributes.errorType.key,
            res.errorCode ?? 'gke.error',
          )
        ]));
        span.setStatus(SpanStatusCode.Error, res.errorMessage);
      }
    }
    return r.value;
  } catch (e, st) {
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
