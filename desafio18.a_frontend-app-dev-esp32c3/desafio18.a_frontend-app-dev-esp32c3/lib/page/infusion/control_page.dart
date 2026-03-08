import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/infusion_controller.dart';
import '../../theme/app_colors.dart';
// importe seu LCD:
import '../../components/premium_lcd.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InfusionController>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          PremiumLcdPainted(value: c.flowRate.toInt(), running: c.isInfusing),
          const SizedBox(height: 18),

          // + / -
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AdjustCircle(
                icon: Icons.remove,
                onTap: () => context.read<InfusionController>().bumpFlow(-5),
              ),
              _AdjustCircle(
                icon: Icons.add,
                onTap: () => context.read<InfusionController>().bumpFlow(5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.18),
              thumbColor: AppColors.accentTeal,
              overlayColor: AppColors.accentTeal.withOpacity(0.14),
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            ),
            child: Slider(
              value: c.flowRate,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (v) => context.read<InfusionController>().setFlow(v),
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.read<InfusionController>().toggleInfusing(),
              icon: Icon(c.isInfusing ? Icons.pause : Icons.play_arrow),
              label: Text(c.isInfusing ? "PAUSAR" : "INICIAR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.isInfusing
                    ? AppColors.warning
                    : AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: () => context.read<InfusionController>().disconnect(),
            icon: const Icon(Icons.power_settings_new, color: AppColors.danger),
            label: const Text(
              "Desligar Equipamento",
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdjustCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AdjustCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: 34, color: AppColors.primary),
      ),
    );
  }
}
