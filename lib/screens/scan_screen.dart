import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  final String analysisType;

  const ScanScreen({
    super.key,
    this.analysisType = 'pest',
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Temporary camera area
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white24,
                  size: 100,
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.eco,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 45),
                ],
              ),
            ),

            // Scan frame
            Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Place plant here',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              left: 20,
              right: 20,
              bottom: 25,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    // Gallery
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Text(
                          'Gallery',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    // Camera button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Camera functionality will be added later.',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF1B5E20),
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    // Flip
                    Column(
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.flip_camera_ios_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Text(
                          'Flip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}