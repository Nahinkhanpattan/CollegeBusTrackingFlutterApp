import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import 'package:collegebus/services/auth_service.dart';
import 'package:collegebus/services/firestore_service.dart';
import 'package:collegebus/widgets/custom_input_field.dart';
import 'package:collegebus/widgets/custom_button.dart';
import 'package:collegebus/utils/constants.dart';
import 'package:collegebus/models/college_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _collegeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rollNumberController = TextEditingController();
  
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;
  List<CollegeModel> _colleges = [];
  CollegeModel? _selectedCollege;
  final _emailIdController = TextEditingController();
  final _emailDomainController = TextEditingController();
  String? _emailDomainHint;
  bool _isLoadingColleges = false;

  @override
  void initState() {
    super.initState();
    _fetchColleges();
  }

  Future<void> _fetchColleges() async {
    setState(() => _isLoadingColleges = true);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    firestoreService.getAllColleges().listen((colleges) {
      setState(() {
        _colleges = colleges;
        _isLoadingColleges = false;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _collegeController.dispose();
    _phoneController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String email = '';
      String collegeName = '';
      String? rollNumber = _selectedRole == UserRole.student ? _rollNumberController.text.trim() : null;
      String? phoneNumber = _phoneController.text.trim();
      if (_selectedRole == UserRole.busCoordinator) {
        email = '${_emailIdController.text.trim()}@${_emailDomainController.text.trim()}';
        collegeName = _collegeController.text.trim();
      } else if (_selectedRole == UserRole.driver) {
        email = '';
        collegeName = _selectedCollege?.name ?? '';
      } else {
        email = _emailController.text.trim();
        collegeName = _selectedCollege?.name ?? '';
        // Validate domain for teacher/student
        if (_selectedRole == UserRole.teacher || _selectedRole == UserRole.student) {
          final domain = email.split('@').last;
          final allowedDomains = _selectedCollege?.allowedDomains ?? [];
          if (!allowedDomains.contains(domain)) {
            _showErrorSnackBar('Email domain must be: ${allowedDomains.join(", ")}');
            setState(() => _isLoading = false);
            return;
          }
        }
      }
      final result = await authService.registerUser(
        email: email,
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        collegeName: collegeName,
        role: _selectedRole,
        phoneNumber: phoneNumber,
        rollNumber: rollNumber,
      );

      if (result['success']) {
        if (result['needsOtpVerification']) {
          context.go('/otp/${_emailController.text.trim()}');
        } else {
          _showSuccessDialog(result['message']);
        }
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Successful'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Center(
                  child: Column(
                    children: [
                      Text(
                        AppStrings.registerTitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        'Join your college bus tracking system',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingXLarge),
                
                // Role selection (moved to top)
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<UserRole>(
                      value: _selectedRole,
                      isExpanded: true,
                      items: UserRole.values
                          .where((role) => role != UserRole.admin)
                          .map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (UserRole? newRole) {
                        if (newRole != null) {
                          setState(() => _selectedRole = newRole);
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Full Name field
                CustomInputField(
                  label: 'Full Name',
                  hint: AppStrings.nameHint,
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // College selection or entry
                if (_selectedRole == UserRole.busCoordinator)
                  CustomInputField(
                    label: 'College Name',
                    hint: AppStrings.collegeHint,
                    controller: _collegeController,
                    prefixIcon: const Icon(Icons.school_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your college name';
                      }
                      return null;
                    },
                  )
                else
                  _isLoadingColleges
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<CollegeModel>(
                        value: _selectedCollege,
                        items: _colleges.map((college) {
                          return DropdownMenuItem(
                            value: college,
                            child: Text(college.name),
                          );
                        }).toList(),
                        onChanged: (college) {
                          setState(() {
                            _selectedCollege = college;
                            if ((_selectedRole == UserRole.teacher || _selectedRole == UserRole.student) && college != null) {
                              _emailDomainHint = 'Domain should be: ${college.allowedDomains.join(", ")}';
                            } else {
                              _emailDomainHint = null;
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select College',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select your college';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: AppSizes.paddingMedium),
                // Email fields
                if (_selectedRole == UserRole.busCoordinator)
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          label: 'Email ID',
                          hint: 'e.g. john.doe',
                          controller: _emailIdController,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter email id';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomInputField(
                          label: 'Domain',
                          hint: 'e.g. rvrjc.ac.in',
                          controller: _emailDomainController,
                          prefixIcon: const Icon(Icons.alternate_email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter domain';
                            }
                            if (!value.contains('.')) {
                              return 'Invalid domain';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  )
                else if (_selectedRole != UserRole.driver && _selectedRole != UserRole.admin)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomInputField(
                        label: 'Email',
                        hint: AppStrings.emailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!EmailValidator.validate(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      if (_emailDomainHint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(
                            _emailDomainHint!,
                            style: const TextStyle(color: AppColors.warning, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                if (_selectedRole != UserRole.driver && _selectedRole != UserRole.admin)
                  const SizedBox(height: AppSizes.paddingMedium),
                // Phone number field (required for all except admin)
                if (_selectedRole != UserRole.admin)
                  CustomInputField(
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (_selectedRole == UserRole.admin) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length < 8) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                if (_selectedRole != UserRole.admin)
                  const SizedBox(height: AppSizes.paddingMedium),
                // Roll number field (only for student)
                if (_selectedRole == UserRole.student)
                  CustomInputField(
                    label: 'Roll Number',
                    hint: 'Enter your roll number',
                    controller: _rollNumberController,
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    validator: (value) {
                      if (_selectedRole != UserRole.student) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter your roll number';
                      }
                      return null;
                    },
                  ),
                if (_selectedRole == UserRole.student)
                  const SizedBox(height: AppSizes.paddingMedium),
                // Password field
                CustomInputField(
                  label: 'Password',
                  hint: AppStrings.passwordHint,
                  controller: _passwordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingMedium),
                
                // Confirm Password field
                CustomInputField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),
                
                // Register button
                CustomButton(
                  text: AppStrings.registerButton,
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: AppSizes.paddingLarge),
                
                // Sign in link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        AppStrings.signIn,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}