import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widget/custom_text_field.dart';

class AddressForm extends StatefulWidget {
  final TextEditingController? line1Controller;
  final TextEditingController? line2Controller;
  final TextEditingController? cityController;
  final TextEditingController? postalController;
  final String? selectedState;
  final GlobalKey<FormState>? formKey;
  final ValueChanged<String?>? onStateChanged;

  const AddressForm({
    super.key,
    this.line1Controller,
    this.line2Controller,
    this.cityController,
    this.postalController,
    this.selectedState,
    this.formKey,
    this.onStateChanged,
  });

  @override
  State<AddressForm> createState() => AddressFormState();
}

class AddressFormState extends State<AddressForm> {
  late final TextEditingController line1Controller;
  late final TextEditingController line2Controller;
  late final TextEditingController cityController;
  late final TextEditingController postalController;
  String? selectedState;
  late final GlobalKey<FormState> _formKey;

  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _isInternalController = widget.line1Controller == null;
    line1Controller = widget.line1Controller ?? TextEditingController();
    line2Controller = widget.line2Controller ?? TextEditingController();
    cityController = widget.cityController ?? TextEditingController();
    postalController = widget.postalController ?? TextEditingController();
    selectedState = widget.selectedState;
    _formKey = widget.formKey ?? GlobalKey<FormState>();
  }

  @override
  void dispose() {
    if (_isInternalController) {
      line1Controller.dispose();
      line2Controller.dispose();
      cityController.dispose();
      postalController.dispose();
    }
    super.dispose();
  }

  bool get _hasAnyData =>
      line1Controller.text.isNotEmpty ||
      cityController.text.isNotEmpty ||
      postalController.text.isNotEmpty ||
      selectedState != null;

  bool validate() {
    if (!_hasAnyData) return true;
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, String> getAddressData() {
    return {
      'line1': line1Controller.text.trim(),
      'line2': line2Controller.text.trim(),
      'city': cityController.text.trim(),
      'postalCode': postalController.text.trim(),
      'state': selectedState ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: line1Controller,
            label: 'Address Line 1',
            hintText: 'Enter address line 1',
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter Address Line 1';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: line2Controller,
            label: 'Address Line 2 (Optional)',
            hintText: 'Enter address line 2',
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: cityController,
            label: 'City',
            hintText: 'Enter city',
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter your city';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomTextField(
            controller: postalController,
            label: 'Postal Code',
            hintText: 'Enter postal code',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            validator: (value) {
              if (_hasAnyData && (value == null || value.trim().isEmpty)) {
                return 'Please enter postal code';
              }
              if (_hasAnyData && value!.trim().length < 5) {
                return 'Postal code must be 5 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _StateDropdownField(
            value: selectedState,
            onChanged: (value) {
              setState(() => selectedState = value);
              widget.onStateChanged?.call(value);
            },
            validator: (value) {
              if (_hasAnyData && value == null) {
                return 'Please select your state';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _StateDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  static const List<String> _malaysiaStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Perak',
    'Perlis',
    'Penang',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
    'Kuala Lumpur',
    'Labuan',
    'Putrajaya',
  ];

  const _StateDropdownField({
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Color(0xFF1B5E20),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBDBDBD), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
            ),
            hintText: 'Select your state',
            hintStyle: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: const TextStyle(
              fontFamily: 'Roboto',
              color: Color(0xFFD32F2F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF2E7D32), size: 28),
          dropdownColor: Colors.white,
          style: const TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF212121),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          items: _malaysiaStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(
                state,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}