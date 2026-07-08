import 'package:flutter/material.dart';
import '../services/pincode_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// Pincode drives City/State via a real lookup (see PincodeService) rather
// than shipping a static list of Indian states/cities to maintain — City
// and State are still presented as dropdowns per the design brief, they're
// just populated from whatever the pincode resolves to.
class AddressFields extends StatefulWidget {
  final String? initialCity;
  final String? initialState;
  final String? initialPincode;
  final void Function(String city, String state, String pincode) onChanged;

  const AddressFields({
    super.key,
    this.initialCity,
    this.initialState,
    this.initialPincode,
    required this.onChanged,
  });

  @override
  State<AddressFields> createState() => _AddressFieldsState();
}

class _AddressFieldsState extends State<AddressFields> {
  final _pincodeService = PincodeService();
  late final TextEditingController _pincodeController;

  List<String> _cityOptions = [];
  String? _selectedCity;
  String? _state;
  bool _looking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pincodeController = TextEditingController(text: widget.initialPincode ?? '');
    _selectedCity = widget.initialCity;
    _state = widget.initialState;
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      _cityOptions = [_selectedCity!];
    }
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _lookup(String pincode) async {
    setState(() {
      _looking = true;
      _error = null;
    });
    try {
      final result = await _pincodeService.lookup(pincode);
      if (result == null) {
        setState(() {
          _error = 'Could not find a location for this pincode';
          _cityOptions = [];
          _selectedCity = null;
          _state = null;
        });
        return;
      }
      setState(() {
        _cityOptions = result.cities;
        _selectedCity = result.cities.contains(_selectedCity) ? _selectedCity : result.cities.first;
        _state = result.state;
      });
      _notify();
    } catch (_) {
      setState(() => _error = 'Could not look up pincode. Check your connection.');
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  void _notify() {
    widget.onChanged(_selectedCity ?? '', _state ?? '', _pincodeController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _pincodeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'Pincode',
            counterText: '',
            suffixIcon: _looking
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (value) {
            final digits = value.trim();
            if (digits.length == 6 && int.tryParse(digits) != null) {
              _lookup(digits);
            } else {
              _notify();
            }
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: AppTypography.bodyMuted.copyWith(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _cityOptions.contains(_selectedCity) ? _selectedCity : null,
                decoration: const InputDecoration(labelText: 'City'),
                hint: const Text('Enter pincode', style: TextStyle(fontSize: 13)),
                items: [
                  for (final city in _cityOptions) DropdownMenuItem(value: city, child: Text(city)),
                ],
                onChanged: _cityOptions.isEmpty
                    ? null
                    : (value) {
                        setState(() => _selectedCity = value);
                        _notify();
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: (_state != null && _state!.isNotEmpty) ? _state : null,
                decoration: const InputDecoration(labelText: 'State'),
                hint: const Text('Enter pincode', style: TextStyle(fontSize: 13)),
                items: (_state != null && _state!.isNotEmpty)
                    ? [DropdownMenuItem(value: _state, child: Text(_state!))]
                    : const [],
                onChanged: null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
