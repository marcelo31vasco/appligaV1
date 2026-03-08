import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

void main() {
  runApp(
    const MaterialApp(
      home: InfusionPumpPage(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class InfusionPumpPage extends StatefulWidget {
  const InfusionPumpPage({super.key});

  @override
  State<InfusionPumpPage> createState() => _InfusionPumpPageState();
}

class _InfusionPumpPageState extends State<InfusionPumpPage> {
  List<ScanResult> _scanResults = [];
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writableCharacteristic;

  bool _isScanning = false;
  String _status = "Aguardando conexão...";

  // Variáveis da Bomba de Infusão
  double _flowRate = 0; // Vai de 0 a 100 (representa %)
  bool _isInfusing = false; // Controle de Play/Pause

  // Limites físicos do seu motor
  final int _minPWM = 210; // Força mínima para o motor começar a girar
  final int _maxPWM = 255;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        setState(() => _status = "Bluetooth desligado!");
      }
    });
    FlutterBluePlus.onScanResults.listen((results) {
      if (mounted) setState(() => _scanResults = results);
    });
  }

  Future<bool> _requestAndroidPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses[Permission.bluetoothScan]!.isDenied ||
          statuses[Permission.bluetoothConnect]!.isDenied ||
          statuses[Permission.location]!.isDenied) {
        setState(() => _status = "Permissões negadas.");
        return false;
      }
    }
    return true;
  }

  void startScan() async {
    bool hasPermissions = await _requestAndroidPermissions();
    if (!hasPermissions) return;

    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      setState(() => _status = "Ative o Bluetooth.");
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Buscando equipamento...";
      _scanResults.clear();
    });

    await FlutterBluePlus.stopScan();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      setState(() => _status = "Erro: $e");
    }

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _status = _scanResults.isEmpty
              ? "Nenhum equipamento encontrado."
              : "Selecione o equipamento:";
        });
      }
    });
  }

  void _connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    setState(() => _status = "Conectando...");

    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? foundChar;

      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            foundChar = c;
            break;
          }
        }
        if (foundChar != null) break;
      }

      if (foundChar != null) {
        setState(() {
          _connectedDevice = device;
          _writableCharacteristic = foundChar;
          _status = "Equipamento pronto";
          _flowRate = 0;
          _isInfusing = false;
        });
      } else {
        await device.disconnect();
        setState(() => _status = "Falha de compatibilidade.");
      }
    } catch (e) {
      setState(() => _status = "Erro ao conectar.");
    }
  }

  // --- LÓGICA DE MAPEAMENTO (O SEGREDO DO MOTOR) ---
  void _applyMotorPower() {
    if (_writableCharacteristic == null) return;

    int pwmValue = 0;

    // Só envia energia se estiver em "Play" e a taxa for maior que 0
    if (_isInfusing && _flowRate > 0) {
      // Mapeia 1-100% para 210-255 PWM
      pwmValue = _minPWM + ((_flowRate / 100) * (_maxPWM - _minPWM)).round();
    }

    _sendPWM(pwmValue);
  }

  void _sendPWM(int value) async {
    try {
      await _writableCharacteristic!.write([value], withoutResponse: true);
    } catch (e) {
      try {
        await _writableCharacteristic!.write([value], withoutResponse: false);
      } catch (e2) {
        debugPrint("Erro: $e2");
      }
    }
  }

  void _disconnect() async {
    _sendPWM(0); // Garante que o motor pare antes de desconectar
    if (_connectedDevice != null) await _connectedDevice!.disconnect();
    setState(() {
      _connectedDevice = null;
      _writableCharacteristic = null;
      _status = "Desconectado";
      _isInfusing = false;
      _flowRate = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ===== PALETA NOVA (Roxo + Teal) =====
    const Color primary = Color(0xFF6D28D9); // roxo
    const Color primaryDark = Color(0xFF4C1D95);
    const Color accentTeal = Color(0xFF00A6A6);

    const Color bg = Color(0xFFF4F6FA);
    const Color surface = Color(0xFFFFFFFF);
    const Color ink = Color(0xFF0F172A);
    const Color muted = Color(0xFF64748B);

    const Color success = Color(0xFF22C55E);
    const Color warning = Color(0xFFF59E0B);
    const Color danger = Color(0xFFEF4444);

    const Color lcdBg = Color(0xFF0B1220);
    const Color lcdBorder = Color(0xFF8B5CF6);
    const Color lcdGlow = Color(0xFF7C3AED);

    final bool isErrorLike =
        _status.toLowerCase().contains("erro") ||
        _status.toLowerCase().contains("falha") ||
        _status.toLowerCase().contains("negada") ||
        _status.toLowerCase().contains("negadas");

    final Color statusColor = isErrorLike
        ? danger
        : (_connectedDevice != null ? success : accentTeal);

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(55),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6D28D9), // roxo
                Color(0xFF4C1D95), // roxo escuro
                Color(0xFF0EA5E9), // azul tech
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset('assets/icons/logov2.png', height: 50),
                  const SizedBox(width: 5),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SISTEMA DE INFUSÃO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        "Bomba de Precisão",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // ===== BODY PREMIUM (gradient leve + sombra no status) =====
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF4F6FA),
              Color(0xFFEFF1FF), // leve lilás
              Color(0xFFF4F6FA),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Barra de status superior com sombra
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: ink,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                _status.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),

            if (_connectedDevice != null) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // LCD DIGITAL
                      PremiumLcdPainted(
                        value: _flowRate.toInt(),
                        running: _isInfusing,
                      ),

                      // CONTROLES (+ / -)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAdjustButton(
                            Icons.remove,
                            () {
                              setState(
                                () => _flowRate = (_flowRate - 5).clamp(0, 100),
                              );
                              _applyMotorPower();
                            },
                            primary,
                            surface,
                            ink,
                          ),
                          _buildAdjustButton(
                            Icons.add,
                            () {
                              setState(
                                () => _flowRate = (_flowRate + 5).clamp(0, 100),
                              );
                              _applyMotorPower();
                            },
                            primary,
                            surface,
                            ink,
                          ),
                        ],
                      ),

                      // SLIDER
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: primary,
                          inactiveTrackColor: primary.withOpacity(0.18),
                          thumbColor: accentTeal,
                          overlayColor: accentTeal.withOpacity(0.14),
                          trackHeight: 10,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 15,
                          ),
                        ),
                        child: Slider(
                          value: _flowRate,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (val) {
                            setState(() => _flowRate = val);
                            _applyMotorPower();
                          },
                        ),
                      ),

                      // BOTÃO START/PAUSE
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() => _isInfusing = !_isInfusing);
                                _applyMotorPower();
                              },
                              icon: Icon(
                                _isInfusing ? Icons.pause : Icons.play_arrow,
                                size: 30,
                              ),
                              label: Text(
                                _isInfusing ? "PAUSAR" : "INICIAR",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                backgroundColor: _isInfusing
                                    ? warning
                                    : success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // DESCONECTAR
                      TextButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(
                          Icons.power_settings_new,
                          color: danger,
                        ),
                        label: const Text(
                          "Desligar Equipamento",
                          style: TextStyle(
                            color: danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // TELA DE SCAN
              Expanded(
                child: ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    final result = _scanResults[index];
                    final name = result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : "Hardware Desconhecido";

                    return Card(
                      color: surface,
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: primary.withOpacity(0.12)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primary.withOpacity(0.10),
                          child: Icon(
                            Icons.medical_services_outlined,
                            color: primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                        subtitle: Text(
                          "Equipamento pronto para parear",
                          style: TextStyle(color: muted),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _connectToDevice(result.device),
                          child: const Text("CONECTAR"),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    _isScanning ? "BUSCANDO..." : "PROCURAR BOMBA DE INFUSÃO",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 60),
                    backgroundColor: ink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para os botões de + e -
  Widget _buildAdjustButton(
    IconData icon,
    VoidCallback onPressed,
    Color primary,
    Color surface,
    Color ink,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: primary.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: ink.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, size: 34, color: primary),
      ),
    );
  }
}

class PremiumLcdPainted extends StatelessWidget {
  final int value;
  final bool running;

  const PremiumLcdPainted({
    super.key,
    required this.value,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    const r = 22.0;

    return LayoutBuilder(
      builder: (context, c) {
        // Largura disponível
        final w = c.maxWidth;

        // Proporção parecida com o print (mais “retângulo”)
        // Ajuste se quiser mais alto/baixo:
        final h = w * 0.52;

        // Tamanhos responsivos (escala)
        final scale = (w / 360).clamp(0.85, 1.15);

        final titleSize = 16 * scale;
        final valueSize = 86 * scale;
        final percentSize = 46 * scale;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r),
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF22D3EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.28),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(0xFF22D3EE).withOpacity(0.16),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r - 2),
            child: SizedBox(
              height: h,
              width: double.infinity,
              child: Stack(
                children: [
                  // Fundo
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF070B1A),
                          Color(0xFF071A2E),
                          Color(0xFF041018),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Pintura (grid/ondas)
                  Positioned.fill(
                    child: CustomPaint(painter: _LcdDecorPainter()),
                  ),

                  // Conteúdo organizado
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18 * scale,
                      vertical: 14 * scale,
                    ),
                    child: Column(
                      children: [
                        // ===== TOPO (título) =====
                        SizedBox(
                          height: 30 * scale,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _TinyDot(color: Color(0xFF8B5CF6)),
                              SizedBox(width: 10 * scale),
                              Text(
                                "TAXA DE FLUXO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  fontSize: titleSize,
                                ),
                              ),
                              SizedBox(width: 10 * scale),
                              const _TinyDot(color: Color(0xFF22D3EE)),
                            ],
                          ),
                        ),

                        // ===== MEIO (número) =====
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    "$value",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: valueSize,
                                      fontWeight: FontWeight.w900,
                                      height: 0.95,
                                    ),
                                  ),
                                  SizedBox(width: 13 * scale),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 10 * scale,
                                    ),
                                    child: Text(
                                      "%",
                                      style: TextStyle(
                                        color: const Color(
                                          0xFF22D3EE,
                                        ).withOpacity(0.95),
                                        fontSize: percentSize,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ===== BASE (pill) =====
                        SizedBox(height: 10 * scale),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _StatusPill(running: running),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool running;
  const _StatusPill({required this.running});

  @override
  Widget build(BuildContext context) {
    final dotColor = running
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);
    final text = running ? "INFUSÃO EM ANDAMENTO" : "PAUSADO";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: running
              ? const [Color(0xFF052B2C), Color(0xFF06323D)]
              : const [Color(0xFF2B1A05), Color(0xFF3A2206)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallDot(color: dotColor),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: dotColor.withOpacity(0.95),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          _SmallDot(color: dotColor),
        ],
      ),
    );
  }
}

class _TinyDot extends StatelessWidget {
  final Color color;
  const _TinyDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.55),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _SmallDot extends StatelessWidget {
  final Color color;
  const _SmallDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.50),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Desenha:
/// - grid suave (fundo)
/// - ondas no canto direito
/// - símbolos "+" no lado esquerdo
/// - highlights roxo/teal
class _LcdDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ===== 1) Grid suave =====
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 22.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // ===== 2) Brilho (radial) =====
    final glowTeal = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF22D3EE).withOpacity(0.18), Colors.transparent],
        radius: 1.0,
        center: const Alignment(0.85, 0.25),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowTeal);

    final glowPurple = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF8B5CF6).withOpacity(0.16), Colors.transparent],
        radius: 1.0,
        center: const Alignment(-0.85, 0.35),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPurple);

    // ===== 3) Símbolos "+" (medical) no lado esquerdo =====
    _drawPlus(
      canvas,
      const Offset(34, 98),
      10,
      const Color(0xFF8B5CF6).withOpacity(0.20),
    );
    _drawPlus(
      canvas,
      const Offset(54, 142),
      7,
      const Color(0xFF8B5CF6).withOpacity(0.16),
    );
    _drawPlus(
      canvas,
      const Offset(28, 165),
      6,
      const Color(0xFF22D3EE).withOpacity(0.12),
    );

    // ===== 4) Ondas no canto direito =====
    final waveRect = Rect.fromLTWH(
      size.width * 0.52,
      size.height * 0.40,
      size.width * 0.52,
      size.height * 0.60,
    );

    final wavePaint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF22D3EE).withOpacity(0.00),
          const Color(0xFF22D3EE).withOpacity(0.35),
          const Color(0xFF8B5CF6).withOpacity(0.12),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(waveRect);

    final wavePaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withOpacity(0.10);

    // desenha várias ondas paralelas
    for (int i = 0; i < 7; i++) {
      final t = i / 6.0;
      final path = _wavePath(
        size,
        startX: size.width * 0.56,
        endX: size.width * 0.98,
        baseY: size.height * (0.60 + t * 0.05),
        amp: 8 + i * 1.2,
        freq: 2.2 + i * 0.15,
      );
      canvas.drawPath(path, i == 0 ? wavePaint1 : wavePaint2);
    }

    // ===== 5) “pontilhado” de tech =====
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.08);
    for (int i = 0; i < 30; i++) {
      final x = size.width * 0.58 + (i * 9) % (size.width * 0.40);
      final y = size.height * 0.25 + ((i * 13) % 80);
      canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
    }
  }

  Path _wavePath(
    Size size, {
    required double startX,
    required double endX,
    required double baseY,
    required double amp,
    required double freq,
  }) {
    final path = Path();
    path.moveTo(startX, baseY);

    final width = endX - startX;
    const samples = 90;

    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final x = startX + width * t;
      final y =
          baseY + math.sin((t * math.pi * 2) * freq) * amp * (0.55 + 0.45 * t);
      path.lineTo(x, y);
    }
    return path;
  }

  void _drawPlus(Canvas canvas, Offset center, double size, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      p,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
