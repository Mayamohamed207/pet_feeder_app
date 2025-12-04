import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pet.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';
import '../services/tflite_service.dart';
import 'dart:async';

class PetFeederScreen extends StatefulWidget {
  @override
  State<PetFeederScreen> createState() => _PetFeederScreenState();
}

class _PetFeederScreenState extends State<PetFeederScreen> {
  late Pet pet;
  int _portionAmount = 0;
  bool _isLoading = false;
  bool _isDetecting = false;
  bool? _catDetected;

  @override
  void initState() {
    super.initState();
    _initializeTFLite();
  }

  Future<void> _initializeTFLite() async {
    try {
      await TFLiteService.initialize();
      print('TFLite initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize TFLite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load AI model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pet = ModalRoute.of(context)!.settings.arguments as Pet;
  }

  @override
  void dispose() {
    TFLiteService.dispose();
    super.dispose();
  }

Future<void> _detectCat() async {
  setState(() {
    _isDetecting = true;
    _catDetected = null;
  });

  try {
    print(' Starting live cat detection...');
   
    final result = await TFLiteService.analyzeLiveFromESP32();
    
    print(' Detection result: $result');

    setState(() {
      _catDetected = result['isCat'] as bool?;
      _isDetecting = false;
    });

    if (mounted && _catDetected != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _catDetected! ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  _catDetected! 
                      ? 'Cat detected!'
                      : 'No cat detected',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _catDetected! 
              ? AppTheme.mintGreen 
              : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print('❌ Detection error: $e');
    
    String errorMessage = 'Detection failed';
    if (e.toString().contains('ESP32')) {
      errorMessage = 'Cannot connect to ESP32 camera';
    } else if (e.toString().contains('timed out')) {
      errorMessage = 'Request timed out. Check connections.';
    } else if (e.toString().contains('502')) {
      errorMessage = 'ESP32 is offline or unreachable';
    } else {
      errorMessage = 'Error: ${e.toString()}';
    }
    
    setState(() {
      _catDetected = null;
      _isDetecting = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

  Future<void> _launchCameraStream() async {
    const String espCameraUrl =
        'https://unsunny-botchiest-khloe.ngrok-free.dev/stream';

    final uri = Uri.parse(espCameraUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot open camera. Check ESP32 IP.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.oceanBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feed ${pet.name}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: FirebaseService.deviceStatusStream,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final lastUpdated = data?['lastUpdated'];
          final isOnline = data?['online'] ?? false;

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 16),

                  Hero(
                    tag: pet.name,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 3, color: AppTheme.oceanBlue),
                      ),
                      child: ClipOval(
                        child: Image.asset(pet.image, fit: BoxFit.cover),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  Text(
                    'Ready to feed ${pet.name}?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepOcean,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24),

              if (_catDetected != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _catDetected! ? Icons.check_circle : Icons.cancel,
                        color: _catDetected! ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _catDetected! ? 'Cat Detected' : 'No Cat Detected',
                        style: TextStyle(
                          color: _catDetected! ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isDetecting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Detecting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(height: 20), 


                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _isDetecting ? Icons.hourglass_empty : Icons.camera_alt,
                        size: 22,
                        color: Colors.white,
                      ),
                      
                      label: Text(
                        _isDetecting ? 'Detecting...' : 'Detect Cat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepOcean,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: (isOnline && !_isDetecting) ? _detectCat : null,
                    ),
                  ),

                  SizedBox(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portion Size',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepOcean,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: AppTheme.deepOcean,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          labelText: 'ml',
                          labelStyle: TextStyle(
                            color: AppTheme.oceanBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.local_dining,
                            color: AppTheme.oceanBlue,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.oceanBlue.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppTheme.oceanBlue,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _portionAmount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        width: 2,
                        color: isOnline ? AppTheme.mintGreen : Colors.red.shade400,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.check_circle : Icons.warning,
                          color: isOnline ? AppTheme.mintGreen : Colors.red,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline ? 'Device Ready' : 'Device Offline',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isOnline
                                      ? AppTheme.deepOcean
                                      : Colors.red.shade800,
                                ),
                              ),
                              if (lastUpdated != null)
                                Text(
                                  'Last: ${DateFormat('hh:mm a, dd MMM').format(DateTime.fromMillisecondsSinceEpoch(lastUpdated))}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            _isLoading ? Icons.hourglass_empty : Icons.pets,
                            size: 22,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isLoading ? 'Feeding...' : 'Dispense Food',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.oceanBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (isOnline && !_isLoading)
                              ? () async {
                                  if (!mounted) return;
                                  setState(() => _isLoading = true);

                                  try {
                                    await FirebaseService.feedNow(_portionAmount);

                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 12),
                                            Text(
                                              'Dispensed $_portionAmount ml',
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.mintGreen,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                }
                              : null,
                        ),
                      ),

                      SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.videocam, size: 22, color: AppTheme.oceanBlue),
                          label: Text(
                            'Live Camera',
                            style: TextStyle(
                              color: AppTheme.oceanBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.oceanBlue, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isOnline ? _launchCameraStream : null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}