// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_gcp_gke_suppression.dart';

class GcpGKEResult {
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

class GcpGKECallResult<T> {
  const GcpGKECallResult({required this.value, this.result});
  final T value;
  final GcpGKEResult? result;
}

Future<T> tracedGcpGKE<T>({
  required String operation,
  required Future<GcpGKECallResult<T>> Function() invoke,
  Tracer? tracer,
}) async {
  if (gcpGKEInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final t = tracer ?? OTel.tracerProvider().getTracer('otel_gcp_gke');
  final span = t.startSpan('gke $operation', kind: SpanKind.client);
  try {
    span.setStringAttribute('gcp.service', 'container');
    final r = await invoke();
    final res = r.result;
    if (res != null) {
      if (res.project != null) {
        span.setStringAttribute('gcp.project.id', res.project!);
      }
      if (res.location != null) {
        span.setStringAttribute('cloud.region', res.location!);
      }
      if (res.clusterName != null) {
        span.setStringAttribute('k8s.cluster.name', res.clusterName!);
      }
      if (res.nodePool != null) {
        span.setStringAttribute('gcp.gke.node_pool', res.nodePool!);
      }
      if (res.podCount != null) {
        span.setIntAttribute('k8s.cluster.pod.count', res.podCount!);
      }
      if (res.version != null) {
        span.setStringAttribute('k8s.cluster.version', res.version!);
      }
      if (res.statusCode != null) {
        span.setIntAttribute('http.response.status_code', res.statusCode!);
      }
      if (res.errorCode != null) {
        span.setStringAttribute('gke.error.code', res.errorCode!);
      }
      final fail =
          res.errorCode != null ||
          (res.statusCode != null && res.statusCode! >= 400);
      if (fail) {
        span.setStringAttribute(
          ErrorResource.errorType.key,
          res.errorCode ?? 'gke.error',
        );
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
