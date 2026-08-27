import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_config.dart';
import 'app/dependencies.dart';

void main() {
  final config = AppConfig.fromEnvironment();
  runApp(FacturaFlowApp(dependencies: Dependencies(config: config)));
}
