import 'package:flutter/material.dart';

const companyName = 'AHEAD AFRICA SOLUTION LTD';
const companyAddress = '5th Floor, Garden Avenue Tower, Ohio St, Dar es Salaam';
const companyPhone = '+255 690 255 556';
const companyWebsite = 'https://aheadafrica.co.tz';

enum CompanyBrand { aheadAfrica, flashnet }

class CompanyProfile {
  const CompanyProfile({
    required this.name,
    required this.address,
    required this.website,
    required this.logoAsset,
    required this.watermarkAsset,
    required this.watermarkOpacity,
    required this.logoWidth,
    required this.logoHeight,
    this.phone,
  });

  final String name;
  final String address;
  final String website;
  final String logoAsset;
  final String watermarkAsset;
  final double watermarkOpacity;
  final double logoWidth;
  final double logoHeight;
  final String? phone;

  String get logoFileName => logoAsset.split('/').last;
}

const aheadAfricaProfile = CompanyProfile(
  name: companyName,
  address: companyAddress,
  phone: companyPhone,
  website: companyWebsite,
  logoAsset: 'assets/ahead_africa_logo.png',
  watermarkAsset: 'assets/ahead_africa_logo.png',
  watermarkOpacity: 0.06,
  logoWidth: 210,
  logoHeight: 70,
);

const flashnetProfile = CompanyProfile(
  name: 'FLASHNET',
  address:
      'Tower, PPF Towers, 1st Floor, Garden Avenue, Ohio St, Dar es Salaam 14300',
  website: 'https://flashnet.co.tz/',
  logoAsset: 'assets/flashnet_header_logo.png',
  watermarkAsset: 'assets/flashnet_watermark_source.png',
  watermarkOpacity: 0.13,
  logoWidth: 280,
  logoHeight: 74,
);

CompanyProfile companyProfileFor(CompanyBrand brand) => switch (brand) {
      CompanyBrand.aheadAfrica => aheadAfricaProfile,
      CompanyBrand.flashnet => flashnetProfile,
    };

class CompanyBrandSelector extends StatelessWidget {
  const CompanyBrandSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final CompanyBrand value;
  final ValueChanged<CompanyBrand> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<CompanyBrand>(
        // ignore: deprecated_member_use
        value: value,
        decoration: const InputDecoration(labelText: 'Document branding'),
        items: const [
          DropdownMenuItem(
            value: CompanyBrand.aheadAfrica,
            child: Text('AHEAD AFRICA'),
          ),
          DropdownMenuItem(
            value: CompanyBrand.flashnet,
            child: Text('FLASHNET'),
          ),
        ],
        onChanged: enabled
            ? (brand) {
                if (brand != null) onChanged(brand);
              }
            : null,
      );
}
