// lib/presentation/widgets/location_dialog.dart
import 'package:flutter/material.dart';

class LocationDialog extends StatefulWidget {
  final Function(double latitude, double longitude) onLocationSelected;

  const LocationDialog({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  bool _useCurrentLocation = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Change Location'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use current location option
            GestureDetector(
              onTap: () {
                setState(() {
                  _useCurrentLocation = true;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _useCurrentLocation
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _useCurrentLocation,
                      onChanged: (value) {
                        setState(() {
                          _useCurrentLocation = value!;
                        });
                      },
                    ),
                    const Icon(Icons.my_location),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Use Current Location'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Manual location entry
            GestureDetector(
              onTap: () {
                setState(() {
                  _useCurrentLocation = false;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: !_useCurrentLocation
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _useCurrentLocation,
                      onChanged: (value) {
                        setState(() {
                          _useCurrentLocation = value!;
                        });
                      },
                    ),
                    const Icon(Icons.edit_location),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Enter Coordinates'),
                    ),
                  ],
                ),
              ),
            ),

            // Manual entry fields
            if (!_useCurrentLocation) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _latitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 28.6139',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _longitudeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. 77.2090',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_useCurrentLocation) {
              // Get current location
              setState(() {
                _isLoading = true;
              });

              try {
                // This would use the location service to get current location
                // For now, we'll just close the dialog
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error getting location: $e')),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            } else {
              // Validate and use manual coordinates
              final latitude = double.tryParse(_latitudeController.text);
              final longitude = double.tryParse(_longitudeController.text);

              if (latitude == null || longitude == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid coordinates')),
                );
                return;
              }

              widget.onLocationSelected(latitude, longitude);
              Navigator.of(context).pop();
            }
          },
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Save'),
        ),
      ],
    );
  }
}