import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pet.dart';
import '../app_theme.dart';
import '../services/firebase_service.dart';

class PetFeederScreen extends StatefulWidget {
  @override
  State<PetFeederScreen> createState() => _PetFeederScreenState();
}

class _PetFeederScreenState extends State<PetFeederScreen> {
  late Pet pet;
  int _portionAmount = 0;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pet = ModalRoute.of(context)!.settings.arguments as Pet;
  }

  Future<void> _launchCameraStream() async {
    const String espCameraUrl = 'http://192.168.1.100:81/stream';
    
    final uri = Uri.parse(espCameraUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,  
      );
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
                  
                  // Pet Avatar
                  Hero(
                    tag: pet.name,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: AppTheme.oceanBlue,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          pet.image,
                          fit: BoxFit.cover,
                        ),
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

                  // Portion Input Card
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant, color: AppTheme.oceanBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Portion Size',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepOcean,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
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
                                  borderSide: BorderSide(color: AppTheme.oceanBlue.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.oceanBlue, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _portionAmount = int.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Device Status
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
                                  color: isOnline ? AppTheme.deepOcean : Colors.red.shade800,
                                ),
                              ),
                              if (lastUpdated != null)
                                Row(
                                  children: [
                                    Text(
                                      'Last: ${DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(lastUpdated))}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${DateFormat('dd MMM').format(DateTime.fromMillisecondsSinceEpoch(lastUpdated))}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Action Buttons
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
                                              'Dispensed $_portionAmount ml ',
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
