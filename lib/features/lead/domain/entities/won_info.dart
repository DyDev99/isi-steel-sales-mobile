import 'package:equatable/equatable.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/onboarding_status.dart';
import 'package:isi_steel_sales_mobile/features/lead/domain/entities/shop_type.dart';

/// [finalValue]/[deliveryTimeline] are captured the moment the deal is
/// marked Won. Everything from [shopType] down is only ever filled in by
/// the "Send to HQ" step and by HQ's own approval — reps never set
/// [approvedCreditLimit] themselves.
class WonInfo extends Equatable {
  const WonInfo({
    required this.finalValue,
    this.deliveryTimeline,
    this.onboardingStatus = OnboardingStatus.notSubmitted,
    this.shopType,
    this.customerCode,
    this.sapCustomerId,
    this.approvedCreditLimit,
    this.approvalDate,
    this.contractDate,
    this.annualRevenue,
    this.productsPurchased = const [],
    this.firstOrderDate,
    this.accountManager,
  });

  final double finalValue;
  final String? deliveryTimeline;
  final OnboardingStatus onboardingStatus;
  final ShopType? shopType;
  final String? customerCode;
  final String? sapCustomerId;
  final double? approvedCreditLimit;
  final DateTime? approvalDate;
  final DateTime? contractDate;
  final double? annualRevenue;
  final List<String> productsPurchased;
  final DateTime? firstOrderDate;
  final String? accountManager;

  WonInfo copyWith({
    double? finalValue,
    String? deliveryTimeline,
    OnboardingStatus? onboardingStatus,
    ShopType? shopType,
    String? customerCode,
    String? sapCustomerId,
    double? approvedCreditLimit,
    DateTime? approvalDate,
    DateTime? contractDate,
    double? annualRevenue,
    List<String>? productsPurchased,
    DateTime? firstOrderDate,
    String? accountManager,
  }) {
    return WonInfo(
      finalValue: finalValue ?? this.finalValue,
      deliveryTimeline: deliveryTimeline ?? this.deliveryTimeline,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      shopType: shopType ?? this.shopType,
      customerCode: customerCode ?? this.customerCode,
      sapCustomerId: sapCustomerId ?? this.sapCustomerId,
      approvedCreditLimit: approvedCreditLimit ?? this.approvedCreditLimit,
      approvalDate: approvalDate ?? this.approvalDate,
      contractDate: contractDate ?? this.contractDate,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      productsPurchased: productsPurchased ?? this.productsPurchased,
      firstOrderDate: firstOrderDate ?? this.firstOrderDate,
      accountManager: accountManager ?? this.accountManager,
    );
  }

  @override
  List<Object?> get props => [
        finalValue,
        deliveryTimeline,
        onboardingStatus,
        shopType,
        customerCode,
        sapCustomerId,
        approvedCreditLimit,
        approvalDate,
        contractDate,
        annualRevenue,
        productsPurchased,
        firstOrderDate,
        accountManager,
      ];
}
