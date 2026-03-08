import 'package:flutter/material.dart';
import 'package:ligaflow/page/infusion/infusion_shell_page.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/ble_service.dart';
import 'services/permissions_service.dart';
import 'controllers/infusion_controller.dart';

class InfusionApp extends StatelessWidget {
  const InfusionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => BleService()),
        Provider(create: (_) => PermissionsService()),
        ChangeNotifierProvider(
          create: (ctx) => InfusionController(
            ble: ctx.read<BleService>(),
            permissions: ctx.read<PermissionsService>(),
          )..init(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppThemeData.light(),
        home: const InfusionShellPage(),
      ),
    );
  }
}
