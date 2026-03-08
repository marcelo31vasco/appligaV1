import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/infusion_controller.dart';
import '../../components/app_header.dart';
import '../../components/status_bar.dart';
import '../../theme/app_colors.dart';
import 'scan_page.dart';
import 'control_page.dart';

class InfusionShellPage extends StatelessWidget {
  const InfusionShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InfusionController>();

    final isErrorLike =
        c.status.toLowerCase().contains("erro") ||
        c.status.toLowerCase().contains("falha") ||
        c.status.toLowerCase().contains("negada");

    final statusColor = isErrorLike
        ? AppColors.danger
        : (c.isConnected ? AppColors.success : AppColors.accentTeal);

    return Scaffold(
      appBar: const AppHeader(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F6FA), Color(0xFFEFF1FF), Color(0xFFF4F6FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            StatusBar(text: c.status, textColor: statusColor),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: c.isConnected ? const ControlPage() : const ScanPage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
