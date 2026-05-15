import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_cards.dart';
import '../../widgets/custom_components.dart';
import '../../widgets/custom_textfield.dart';
import '../../models/user_model.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({Key? key}) : super(key: key);

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() async {
    final appointmentService = context.read<AppointmentService>();
    final doctors = await appointmentService.getDoctors();
    setState(() {
      _doctors = doctors;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AppointmentService>(
        builder: (context, appointmentService, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Select Doctor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                if (appointmentService.isLoading)
                  const CustomLoadingIndicator(message: 'Loading doctors...')
                else if (_doctors.isEmpty)
                  const EmptyState(
                    icon: Icons.local_hospital,
                    title: 'No Doctors Available',
                    message: 'Please try again later',
                  )
                else
                  Column(
                    children: _doctors.map((doctor) {
                      final isSelected = _selectedDoctor == doctor['id'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDoctor = doctor['id'];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.primaryBlue : AppColors.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DoctorCard(
                            doctorId: doctor['id'],
                            name: doctor['name'],
                            specialization: doctor['specialization'],
                            rating: doctor['rating'],
                            experience: doctor['experience'],
                            isAvailable: doctor['available'],
                            nextAvailable: doctor['nextAvailable'],
                            onTap: () {},
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        Duration(days: AppConstants.appointmentBookingDaysAhead),
                      ),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _selectedDate = selectedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Select a date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDate == null ? AppColors.textGray : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedTime,
                    isExpanded: true,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    hint: const Text('Select a time slot'),
                    items: AppConstants.timeSlots.map((time) {
                      return DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTime = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Reason for Visit',
                  hint: 'Select reason for appointment',
                  controller: _reasonController,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 32),
                CustomButton(
                  label: 'Book Appointment',
                  isLoading: appointmentService.isLoading,
                  onPressed: _selectedDoctor == null ||
                          _selectedDate == null ||
                          _selectedTime == null ||
                          _reasonController.text.isEmpty
                      ? null
                      : () async {
                          final doctor = _doctors.firstWhere((d) => d['id'] == _selectedDoctor);
                          final user = context.read<AuthService>().currentUser;
                          final success = await appointmentService.bookAppointment(
                            patientId: user?.id ?? '',
                            patientName: user?.fullName ?? '',
                            doctorId: _selectedDoctor!,
                            doctorName: doctor['name'],
                            specialization: doctor['specialization'],
                            appointmentDate: _selectedDate!,
                            appointmentTime: _selectedTime!,
                            reason: _reasonController.text,
                          );
                          if (mounted && success) {
                            showDialog(
                              context: context,
                              builder: (context) => SuccessDialog(
                                title: 'Success',
                                message: 'Appointment booked successfully',
                                onDismiss: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
