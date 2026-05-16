// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_aws_api_gateway/otel_aws_api_gateway.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_aws_api_gateway-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('invoke.proxy records api kind + stage + integration latency', () async {
    await tracedAwsApiGateway<String>(
      operation: 'invoke.proxy',
      invoke: () async => const AwsApiGatewayCallResult(
        value: 'ok',
        result: AwsApiGatewayResult(
          region: 'us-east-1',
          apiKind: 'http',
          httpApiId: 'abc123',
          stage: r'$default',
          routeKey: 'GET /users/{userId}',
          method: 'GET',
          authorizerKind: 'JWT',
          authorized: true,
          integrationLatencyMs: 42,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('aws_api_gateway invoke.proxy')!);
    expect(a['aws_api_gateway.api.kind'], 'http');
    expect(a['aws_api_gateway.route_key'], 'GET /users/{userId}');
    expect(a['aws_api_gateway.integration.latency_ms'], 42);
  });

  test('unauthorized sets span error', () async {
    await tracedAwsApiGateway<String>(
      operation: 'invoke.proxy',
      invoke: () async => const AwsApiGatewayCallResult(
        value: 'ok',
        result: AwsApiGatewayResult(authorized: false),
      ),
    );
    expect(
      spans.findSpanByName('aws_api_gateway invoke.proxy')!.status,
      SpanStatusCode.Error,
    );
  });

  test('TooManyRequestsException sets span error', () async {
    await tracedAwsApiGateway<String>(
      operation: 'restApi.deploy',
      invoke: () async => const AwsApiGatewayCallResult(
        value: 'ok',
        result: AwsApiGatewayResult(
          errorCode: 'TooManyRequestsException',
          statusCode: 429,
        ),
      ),
    );
    expect(
      spans.findSpanByName('aws_api_gateway restApi.deploy')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutAwsApiGatewayInstrumentationAsync(() async {
      await tracedAwsApiGateway<String>(
        operation: 'restApi.list',
        invoke: () async => const AwsApiGatewayCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('aws_api_gateway '), isEmpty);
  });
}
