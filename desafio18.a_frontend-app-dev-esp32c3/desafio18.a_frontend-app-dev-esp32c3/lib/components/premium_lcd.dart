import 'dart:math' as math;

import 'package:flutter/material.dart';

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
