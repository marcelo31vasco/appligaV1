import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/infusion_controller.dart';
import '../../components/scan_device_tile.dart';
import '../../theme/app_colors.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InfusionController>();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: c.scanResults.length,
            itemBuilder: (_, i) {
              final r = c.scanResults[i];
              return ScanDeviceTile(
                result: r,
                onConnect: () =>
                    context.read<InfusionController>().connect(r.device),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: c.isScanning
                  ? null
                  : () => context.read<InfusionController>().startScan(),
              icon: c.isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                c.isScanning ? "BUSCANDO..." : "PROCURAR BOMBA DE INFUSÃO",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
