// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_aws_api_gateway_suppression.dart';

const _tracerName = 'dartastic_otel_libs_aws_api_gateway';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AwsApiGatewayResult {
  const AwsApiGatewayResult({
    this.region,
    this.apiKind,
    this.restApiId,
    this.httpApiId,
    this.websocketApiId,
    this.stage,
    this.resourcePath,
    this.method,
    this.routeKey,
    this.protocolType,
    this.endpointType,
    this.authorizerKind,
    this.authorized,
    this.invokeUrl,
    this.requestBytes,
    this.responseBytes,
    this.integrationLatencyMs,
    this.deploymentId,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `us-east-1`, `eu-west-1`, ...
  final String? region;

  /// `rest`, `http`, `websocket`.
  final String? apiKind;

  final String? restApiId;
  final String? httpApiId;
  final String? websocketApiId;

  /// Deployment stage name.
  final String? stage;

  /// Resource path template (`/users/{userId}`).
  final String? resourcePath;

  /// `GET`, `POST`, `ANY`, ...
  final String? method;

  /// HTTP API route key (`GET /users/{userId}` or `$connect`).
  final String? routeKey;

  /// `WEBSOCKET`, `HTTP` (HTTP APIs).
  final String? protocolType;

  /// `EDGE`, `REGIONAL`, `PRIVATE`.
  final String? endpointType;

  /// `NONE`, `AWS_IAM`, `CUSTOM`, `COGNITO_USER_POOLS`, `JWT`.
  final String? authorizerKind;

  /// Authorizer authorized the principal.
  final bool? authorized;

  /// Resolved invoke URL.
  final String? invokeUrl;

  final int? requestBytes;
  final int? responseBytes;

  /// Backend integration latency from the API Gateway response.
  final int? integrationLatencyMs;

  /// Deployment id created/triggered.
  final String? deploymentId;

  /// AWS error code (`AccessDeniedException`, `LimitExceededException`,
  /// `NotFoundException`, `TooManyRequestsException`, `UnauthorizedException`,
  /// `BadRequestException`, `ConflictException`, ...).
  final String? errorCode;
  final String? errorMessage;

  /// HTTP gateway response status.
  final int? statusCode;
}

class AwsApiGatewayCallResult<T> {
  const AwsApiGatewayCallResult({required this.value, this.result});
  final T value;
  final AwsApiGatewayResult? result;
}

/// Wraps an AWS API Gateway control-plane or invocation call in a CLIENT
/// span. [operation] is one of `restApi.create`, `restApi.delete`,
/// `restApi.get`, `restApi.list`, `restApi.update`, `restApi.deploy`,
/// `restApi.createDeployment`, `restApi.getDeployment`,
/// `restApi.flushStageCache`, `httpApi.create`, `httpApi.delete`,
/// `httpApi.get`, `httpApi.list`, `httpApi.update`, `route.create`,
/// `route.delete`, `route.update`, `integration.create`,
/// `integration.update`, `stage.create`, `stage.update`,
/// `authorizer.create`, `authorizer.delete`, `usagePlan.create`,
/// `usagePlan.delete`, `usagePlan.list`, `apiKey.create`, `apiKey.delete`,
/// `websocket.postToConnection`, `websocket.getConnection`,
/// `websocket.deleteConnection`, `invoke.proxy`, `invoke.execute`.
Future<T> tracedAwsApiGateway<T>({
  required String operation,
  required Future<AwsApiGatewayCallResult<T>> Function() invoke,
}) async {
  if (awsApiGatewayInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'aws_api_gateway',
    'rpc.method': operation,
    'aws_api_gateway.operation': operation,
  };

  final span = _tracer().startSpan(
    'aws_api_gateway $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.region != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.region',
          res.region!,
        ));
      }
      if (res.apiKind != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.api.kind',
          res.apiKind!,
        ));
      }
      if (res.restApiId != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.rest_api.id',
          res.restApiId!,
        ));
      }
      if (res.httpApiId != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.http_api.id',
          res.httpApiId!,
        ));
      }
      if (res.websocketApiId != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.websocket_api.id',
          res.websocketApiId!,
        ));
      }
      if (res.stage != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.stage',
          res.stage!,
        ));
      }
      if (res.resourcePath != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.resource.path',
          res.resourcePath!,
        ));
      }
      if (res.method != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.method',
          res.method!,
        ));
      }
      if (res.routeKey != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.route_key',
          res.routeKey!,
        ));
      }
      if (res.protocolType != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.protocol_type',
          res.protocolType!,
        ));
      }
      if (res.endpointType != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.endpoint_type',
          res.endpointType!,
        ));
      }
      if (res.authorizerKind != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.authorizer.kind',
          res.authorizerKind!,
        ));
      }
      if (res.authorized != null) {
        extras.add(OTel.attributeBool(
          'aws_api_gateway.authorized',
          res.authorized!,
        ));
        if (!res.authorized!) {
          span.setStatus(
            SpanStatusCode.Error,
            'API Gateway authorization failed',
          );
        }
      }
      if (res.invokeUrl != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.invoke_url',
          res.invokeUrl!,
        ));
      }
      if (res.requestBytes != null) {
        extras.add(OTel.attributeInt(
          'aws_api_gateway.request.bytes',
          res.requestBytes!,
        ));
      }
      if (res.responseBytes != null) {
        extras.add(OTel.attributeInt(
          'aws_api_gateway.response.bytes',
          res.responseBytes!,
        ));
      }
      if (res.integrationLatencyMs != null) {
        extras.add(OTel.attributeInt(
          'aws_api_gateway.integration.latency_ms',
          res.integrationLatencyMs!,
        ));
      }
      if (res.deploymentId != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.deployment.id',
          res.deploymentId!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.error.code',
          res.errorCode!,
        ));
        span.setStatus(
          SpanStatusCode.Error,
          'API Gateway ${res.errorCode}',
        );
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'aws_api_gateway.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'API Gateway HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
