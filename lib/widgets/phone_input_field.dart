import 'package:flutter/material.dart';
import 'package:collegebus/utils/constants.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String countryCode;
  final bool enabled;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.countryCode = '+91',
    this.enabled = true,
    this.validator,
    this.onChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Country code display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            color: widget.enabled ? Colors.white : Colors.grey.shade100,
          ),
          child: Text(
            widget.countryCode,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: widget.enabled ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        // Phone number input
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            enabled: widget.enabled,
            validator: widget.validator,
            onChanged: (value) {
              // Remove any country code if user types it
              if (value.startsWith(widget.countryCode)) {
                widget.controller.text = value.substring(widget.countryCode.length);
                widget.controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: widget.controller.text.length),
                );
              }
              widget.onChanged?.call();
            },
                         decoration: InputDecoration(
               labelText: widget.label ?? 'Phone Number',
               hintText: widget.hint ?? '9876543210',
               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
               // Remove the left border since it's connected to country code
               border: const OutlineInputBorder(
                 borderRadius: BorderRadius.only(
                   topRight: Radius.circular(4),
                   bottomRight: Radius.circular(4),
                 ),
               ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                borderSide: BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 