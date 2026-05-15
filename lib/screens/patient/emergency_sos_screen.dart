import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/emergency_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_components.dart';
import '../../models/user_model.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({Key? key}) : super(key: key);

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  final _descriptionController = TextEditingController();
  bool _shareLocation = false;
  bool _submitted = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<EmergencyService>(
        builder: (context, emergencyService, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _submitted
                  ? _buildSuccessScreen(context)
                  : Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.emergency,
                            size: 80,
                            color: AppColors.emergencyRed,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppConstants.emergencySOS,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use this only for medical emergencies',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGray,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.emergencyRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.emergencyRed.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'When to use Emergency SOS:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.emergencyRed,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _EmergencyListItem('Severe chest pain or difficulty breathing'),
                              _EmergencyListItem('Severe allergic reactions'),
                              _EmergencyListItem('Loss of consciousness'),
                              _EmergencyListItem('Severe bleeding or trauma'),
                              _EmergencyListItem('Acute symptoms needing immediate help'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          label: 'Describe Emergency',
                          hint: 'Briefly describe what is happening',
                          controller: _descriptionController,
                          maxLines: 4,
                          minLines: 3,
                          prefixIcon: Icons.note,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Description is required';
                            }
                            return null;
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _shareLocation,
                                onChanged: (value) {
                                  setState(() {
                                    _shareLocation = value ?? false;
                                  });
                                },
                                activeColor: AppColors.infoBlue,
                              ),
                              const Expanded(
                                child: Text(
                                  'Share my location with emergency responders',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textGray,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        EmergencyButton(
                          label: AppConstants.requestHelp,
                          isLoading: emergencyService.isLoading,
                          onPressed: _descriptionController.text.isEmpty
                              ? null
                              : () async {
                                  final user = context.read<AuthService>().currentUser as Patient?;
                                  final success = await emergencyService.requestEmergency(
                                    patientId: user?.id ?? '',
                                    patientName: user?.fullName ?? '',
                                    patientPhone: user?.phone ?? '',
                                    description: _descriptionController.text,
                                    latitude: _shareLocation ? 5.6037 : null,
                                    longitude: _shareLocation ? -0.1870 : null,
                                  );
                                  if (mounted && success) {
                                    setState(() {
                                      _submitted = true;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.successGreen,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Emergency Request Sent',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Emergency responders have been notified',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGray,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'What happens next:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.infoBlue,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '• Emergency team has been alerted\n• Ambulance will be dispatched if needed\n• You will receive updates via SMS\n• Call 112 if immediate help is critical',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        CustomButton(
          label: 'Back to Home',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/patient-home');
          },
        ),
      ],
    );
  }
}

class _EmergencyListItem extends StatelessWidget {
  final String text;

  const _EmergencyListItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 2),
            child: Icon(Icons.check, size: 16, color: AppColors.emergencyRed),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.emergencyRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
