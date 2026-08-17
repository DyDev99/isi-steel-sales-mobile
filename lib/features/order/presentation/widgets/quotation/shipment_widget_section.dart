import 'package:flutter/material.dart';

enum ShipmentMethod { pickup, delivery }
enum PickupLocation { factory, branch }
enum DeliveryAddressOption { defaultAddress, newAddress }

class ShipmentSelectionWidget extends StatelessWidget {
  const ShipmentSelectionWidget({
    super.key,
    required this.method,
    required this.pickupLocation,
    required this.deliveryOption,
    required this.onMethodChanged,
    required this.onPickupLocationChanged,
    required this.onDeliveryOptionChanged,
    this.selectedFactory,
    this.selectedBranch,
    this.onFactoryChanged,
    this.onBranchChanged,
    this.defaultAddress,
    this.newAddressController,
    this.newPhoneController,
    this.onAddressFieldsChanged,
  });

  final ShipmentMethod method;
  final PickupLocation? pickupLocation;
  final DeliveryAddressOption? deliveryOption;
  
  final ValueChanged<ShipmentMethod> onMethodChanged;
  final ValueChanged<PickupLocation> onPickupLocationChanged;
  final ValueChanged<DeliveryAddressOption> onDeliveryOptionChanged;

  // Selected dropdown values & callbacks
  final String? selectedFactory;
  final String? selectedBranch;
  final ValueChanged<String?>? onFactoryChanged;
  final ValueChanged<String?>? onBranchChanged;

  final String? defaultAddress;
  final TextEditingController? newAddressController;
  final TextEditingController? newPhoneController;
  final VoidCallback? onAddressFieldsChanged;

  // Mock data for Factories
  static const List<String> _mockFactories = [
    'Main Factory - Veng Sreng',
    'Factory 2 - Kilometer 6',
    'Factory 3 - Kandal',
    'Factory 4 - Kampong Speu',
    'Factory 5 - Sihanoukville SEZ',
  ];

  // Mock data for Branches
  static const List<String> _mockBranches = [
    'Phnom Penh Branch - Toul Kork',
    'Siem Reap Branch',
    'Battambang Branch',
    'Kampong Cham Branch',
    'Takeo Branch',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Step 1: Delivery vs Pick up
        Text(
          'Method of shipment',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Delivery Option
            Expanded(
              child: _SelectCard(
                title: 'Delivery',
                icon: Icons.local_shipping_outlined,
                isSelected: method == ShipmentMethod.delivery,
                onTap: () => onMethodChanged(ShipmentMethod.delivery),
              ),
            ),
            const SizedBox(width: 12),
            // Pick up Option
            Expanded(
              child: _SelectCard(
                title: 'Pick up',
                icon: Icons.storefront_outlined,
                isSelected: method == ShipmentMethod.pickup,
                onTap: () => onMethodChanged(ShipmentMethod.pickup),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Step 2 (Conditional): Options based on selected shipment method
        if (method == ShipmentMethod.pickup) ...[
          // Sub-options for Pickup: Factory vs Branch
          Text(
            'Pickup Location',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectCard(
                  title: 'Factory',
                  icon: Icons.factory_outlined,
                  isSelected: pickupLocation == PickupLocation.factory,
                  onTap: () => onPickupLocationChanged(PickupLocation.factory),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectCard(
                  title: 'Branch',
                  icon: Icons.store_outlined,
                  isSelected: pickupLocation == PickupLocation.branch,
                  onTap: () => onPickupLocationChanged(PickupLocation.branch),
                ),
              ),
            ],
          ),

          // Factory Dropdown
          if (pickupLocation == PickupLocation.factory) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _mockFactories.contains(selectedFactory)
                  ? selectedFactory
                  : _mockFactories.first,
              decoration: InputDecoration(
                labelText: 'Select Factory Location',
                prefixIcon: const Icon(Icons.factory_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _mockFactories
                  .map((factory) => DropdownMenuItem(
                        value: factory,
                        child: Text(
                          factory,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: onFactoryChanged,
            ),
          ],

          // Branch Dropdown
          if (pickupLocation == PickupLocation.branch) ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _mockBranches.contains(selectedBranch)
                  ? selectedBranch
                  : _mockBranches.first,
              decoration: InputDecoration(
                labelText: 'Select Branch Location',
                prefixIcon: const Icon(Icons.store_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _mockBranches
                  .map((branch) => DropdownMenuItem(
                        value: branch,
                        child: Text(
                          branch,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: onBranchChanged,
            ),
          ],
        ] else if (method == ShipmentMethod.delivery) ...[
          // Sub-options for Delivery: SAP Address vs New Address
          Text(
            'Delivery Address',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Default Address Option (follow SAP)
          _DeliveryOptionTile(
            title: 'Default address (follow SAP)',
            subtitle: defaultAddress,
            isSelected: deliveryOption == DeliveryAddressOption.defaultAddress,
            onTap: () =>
                onDeliveryOptionChanged(DeliveryAddressOption.defaultAddress),
          ),

          const SizedBox(height: 10),

          // New Address Option
          _DeliveryOptionTile(
            title: 'Input new address & phone number',
            subtitle: null,
            isSelected: deliveryOption == DeliveryAddressOption.newAddress,
            onTap: () =>
                onDeliveryOptionChanged(DeliveryAddressOption.newAddress),
          ),

          // Step 3 (Conditional): Inputs for New Address and Phone Number
          if (deliveryOption == DeliveryAddressOption.newAddress) ...[
            const SizedBox(height: 14),
            TextField(
              controller: newAddressController,
              maxLines: 2,
              onChanged: (_) => onAddressFieldsChanged?.call(),
              decoration: InputDecoration(
                labelText: 'New Address',
                hintText: 'Enter new delivery address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPhoneController,
              keyboardType: TextInputType.phone,
              onChanged: (_) => onAddressFieldsChanged?.call(),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter contact phone number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final activeBgColor = colorScheme.primaryContainer.withValues(alpha: 0.35);

    return Material(
      color: isSelected ? activeBgColor : colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryColor : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryOptionTile extends StatelessWidget {
  const _DeliveryOptionTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final activeBgColor = colorScheme.primaryContainer.withValues(alpha: 0.35);

    return Material(
      color: isSelected ? activeBgColor : colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primaryColor : colorScheme.outlineVariant,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? primaryColor : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}