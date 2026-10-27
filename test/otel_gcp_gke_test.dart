// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:otel_gcp_gke/otel_gcp_gke.dart';
import 'package:test/test.dart';

void main() {
  group('otel_gcp_gke', () {
    test('suppression toggles in zone', () async {
      expect(gcpGKEInstrumentationSuppressed(), isFalse);
      await runWithoutGcpGKEInstrumentationAsync(() async {
        expect(gcpGKEInstrumentationSuppressed(), isTrue);
      });
      expect(gcpGKEInstrumentationSuppressed(), isFalse);
    });

    test('GcpGKEResult fields default null', () {
      const r = GcpGKEResult();
      expect(r.statusCode, isNull);
    });
  });
}
