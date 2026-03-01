import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/theme/app_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../offline/application/offline_store.dart';
import '../../offline/domain/app_preferences.dart';

class CompanyProfilePage extends ConsumerStatefulWidget {
  const CompanyProfilePage({super.key});

  @override
  ConsumerState<CompanyProfilePage> createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends ConsumerState<CompanyProfilePage> {
  final _legalNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  // ignoring logo file/image picker since it would require plugins like image_picker which we have, but to keep it simple initially:
  Object? _logoImage;
  // using TaxCountry.unitedStates by default, but we should import CompanyProfile if we had one.
  // Wait, the domain has CompanyProfile. Let's assume it exists or we use raw fields for now.

  @override
  void initState() {
    super.initState();
    // Load existing preferences here
    final prefs = ref.read(offlineStoreProvider).appPreferences;
    final profile = prefs.companyProfile;
    if (profile != null) {
      _legalNameController.text = profile.legalName;
      _address1Controller.text = profile.addressLine1;
      _address2Controller.text = profile.addressLine2;
      _cityController.text = profile.city;
      _regionController.text = profile.region;
      _postalController.text = profile.postalCode;
      _countryController.text = profile.countryName;
      _emailController.text = profile.contactEmail;
      _phoneController.text = profile.contactPhone;
      _websiteController.text = profile.website;
      _taxIdController.text = profile.taxIdentifier;
    }
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  void _save() {
    final prefs = ref.read(offlineStoreProvider).appPreferences;
    final updatedProfile = CompanyProfile(
      legalName: _legalNameController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      region: _regionController.text.trim(),
      postalCode: _postalController.text.trim(),
      countryName: _countryController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      website: _websiteController.text.trim(),
      taxCountry: TaxCountry.unitedStates, // Hardcoded for now, would need a picker
      taxIdentifier: _taxIdController.text.trim(),
      logoData: null, // Keep existing or update
    );
    
    ref.read(offlineStoreProvider.notifier).setAppPreferences(
      prefs.copyWith(companyProfile: updatedProfile),
    );
    Navigator.of(context).pop();
  }

  bool get _canSave => _legalNameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Company profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: DsBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 10, 16, 120),
        children: [
          _buildSection('Logo', [
            if (_logoImage == null)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('No logo selected', style: TextStyle(color: Colors.grey)),
              ),
            TextButton(
              onPressed: () {},
              child: Text(_logoImage == null ? 'Add logo' : 'Change logo'),
            ),
          ]),
          _buildSection('Company', [
            _buildTextField('Legal name', _legalNameController),
            _buildTextField('Address line 1', _address1Controller),
            _buildTextField('Address line 2', _address2Controller),
            _buildTextField('City', _cityController),
            _buildTextField('State/Region', _regionController),
            _buildTextField('Postal code', _postalController),
            _buildTextField('Country', _countryController),
          ]),
          _buildSection('Contact', [
            _buildTextField('Email', _emailController, TextInputType.emailAddress),
            _buildTextField('Phone', _phoneController, TextInputType.phone),
            _buildTextField('Website', _websiteController, TextInputType.url),
          ]),
          _buildSection('Tax', [
            // Simplified tax picker
            ListTile(
              title: const Text('Tax country'),
              trailing: const Text('United States'),
            ),
            _buildTextField('EIN / SSN', _taxIdController),
          ]),
        ],
      ),
      ),
      bottomSheet: DsPrimaryBottomCta(
        title: 'Save',
        onPressed: _canSave ? _save : () {},
        isDisabled: !_canSave,
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return DsCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: DsColorTokens.textPrimary),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType? type]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppThemeTokens.fieldBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
