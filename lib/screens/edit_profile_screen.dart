import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/address_fields.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/shine_effect.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late String _city;
  late String _state;
  late String _pincode;
  String? _photoBase64;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _city = user?.city ?? '';
    _state = user?.state ?? '';
    _pincode = user?.pincode ?? '';
    _photoBase64 = user?.photoBase64;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthService>().updateProfile(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            city: _city,
            state: _state,
            pincode: _pincode,
            photoBase64: _photoBase64,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final user = context.read<AuthService>().user;
    final initial = (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('editProfile').toUpperCase())),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: ProfilePhotoPicker(
                  photoBase64: _photoBase64,
                  fallbackInitial: initial,
                  onChanged: (base64) => setState(() => _photoBase64 = base64),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: strings.t('address')),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              AddressFields(
                initialCity: user?.city,
                initialState: user?.state,
                initialPincode: user?.pincode,
                onChanged: (city, state, pincode) {
                  _city = city;
                  _state = state;
                  _pincode = pincode;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              ShineEffect(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'SAVING...' : 'SAVE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
