import 'package:flutter/material.dart';
import '../models/feeding_data.dart';

class FeedingStatus extends StatelessWidget {
  final FeedingData data;

  const FeedingStatus({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Fed at: ${data.time.hour}:${data.time.minute.toString().padLeft(2, '0')}'),
        subtitle: Text('Weight: ${data.weight} g'),
        trailing: Icon(
          data.petPresent ? Icons.pets : Icons.block,
          color: data.petPresent ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
