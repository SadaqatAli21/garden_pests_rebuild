import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlantScanAnimation extends StatefulWidget {
  final double? size;
  const PlantScanAnimation({super.key, this.size});

  @override
  State<PlantScanAnimation> createState() => _PlantScanAnimationState();
}

class _PlantScanAnimationState extends State<PlantScanAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _cycleIndex = 0;

  final List<Map<String, String>> _pests = [
    {'name': 'Aphids', 'image': 'assets/images/pests/aphids.jpg'},
    {'name': 'Grasshopper', 'image': 'assets/images/pests/grasshopper.webp'},
    {'name': 'Leaf Beetle', 'image': 'assets/images/pests/leaf beetle.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _cycleIndex = (_cycleIndex + 1) % _pests.length;
        });
        _controller.forward(from: 0);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        final double centerSize = totalWidth * 0.45;
        final double sideSize = totalWidth * 0.28;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: centerSize + 5, // Reduced from +20
              width: totalWidth,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(_pests.length, (index) {
                  return _buildSwappingSlot(
                    index,
                    totalWidth,
                    centerSize,
                    sideSize,
                  );
                }),
              ),
            ),
            const SizedBox(height: 5), // Reduced from 12
            // High-Contrast Pill Text for the Center Slot
            _buildCenterText(),
          ],
        );
      },
    );
  }

  Widget _buildSwappingSlot(
      int imageIndex,
      double totalWidth,
      double centerSize,
      double sideSize,
      ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = _controller.value;

        // Slot logic:
        // Slot 0: Center, Slot 1: Right, Slot 2: Left

        // Calculate the current slot for this imageIndex based on cycle
        // Every cycleIndex, images move 1 slot forward
        int currentSlot = (imageIndex - _cycleIndex) % 3;
        if (currentSlot < 0) currentSlot += 3;

        // Target slot (where it's moving TO)
        int nextSlot = (currentSlot - 1) % 3;
        if (nextSlot < 0) nextSlot += 3;

        // Position and Scale mapping for slots
        // Slot Indices: 0=Center, 1=Right, 2=Left

        double getX(int slot) {
          if (slot == 0) return 0; // Center
          if (slot == 1) return totalWidth * 0.4; // Right
          return -totalWidth * 0.4; // Left
        }

        double getScale(int slot) {
          return (slot == 0) ? 1.0 : 0.7;
        }

        double getOpacity(int slot) {
          return (slot == 0) ? 1.0 : 0.4;
        }

        // Interpolate between current and next slot as T goes 0->1
        // We only move during the first 25% of the 4s duration (1s)
        // or we can make it a continuous slow slide.
        // User said "switch krti raha positions apni", let's make it a snappy switch at the start.

        double moveT = (t / 0.2).clamp(
          0.0,
          1.0,
        ); // Shift happens in first 20% (0.8s)
        moveT = Curves.easeInOutCubic.transform(moveT);

        double x =
            getX(currentSlot) + (getX(nextSlot) - getX(currentSlot)) * moveT;
        double scale =
            getScale(currentSlot) +
                (getScale(nextSlot) - getScale(currentSlot)) * moveT;
        double opacity =
            getOpacity(currentSlot) +
                (getOpacity(nextSlot) - getOpacity(currentSlot)) * moveT;

        bool isCenteredNow =
            (currentSlot == 0 && moveT < 0.5) ||
                (nextSlot == 0 && moveT >= 0.5);

        // Scan line logic for the one currently moving INTO or being IN the center
        bool showScanLine = false;
        if (isCenteredNow && t > 0.25 && t < 0.65) {
          showScanLine = true;
        }

        return Transform.translate(
          offset: Offset(x, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: _buildImageCard(
                imageIndex,
                isCenteredNow,
                centerSize,
                showScanLine,
                t,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(
      int index,
      bool isFocused,
      double size,
      bool showScanLine,
      double t,
      ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isFocused ? Colors.white : Colors.white24,
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(_pests[index]['image']!, fit: BoxFit.cover),
            if (showScanLine) _buildScanLine(size, t),
            // Vignette
            if (isFocused)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                    radius: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanLine(double size, double t) {
    // Scan line moves during the phase 0.25 to 0.65
    double progress = (t - 0.25) / 0.4;
    progress = progress.clamp(0.0, 1.0);

    return Positioned(
      top: progress * size,
      left: 0,
      right: 0,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCenterText() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Only show text after the scan line is nearly finished (approx. 65% of cycle)
        double textOpacity = 0.0;
        if (_controller.value > 0.65) {
          textOpacity = ((_controller.value - 0.65) / 0.1).clamp(0.0, 1.0);
        }

        return Opacity(
          opacity: textOpacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              _pests[_cycleIndex]['name']!.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
