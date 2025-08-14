enum SubscriptionPlan {
  monthly,
  quarterly,
  yearly,
}

extension SubscriptionPlanExtension on SubscriptionPlan {
  String get name {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 'Monthly';
      case SubscriptionPlan.quarterly:
        return 'Quarterly';
      case SubscriptionPlan.yearly:
        return 'Yearly';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.monthly:
        return '30 days';
      case SubscriptionPlan.quarterly:
        return '90 days';
      case SubscriptionPlan.yearly:
        return '365 days';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 6.99;
      case SubscriptionPlan.quarterly:
        return 17.99;
      case SubscriptionPlan.yearly:
        return 59.99;
    }
  }

  int get durationInDays {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 30;
      case SubscriptionPlan.quarterly:
        return 90;
      case SubscriptionPlan.yearly:
        return 365;
    }
  }

  double get monthlyEquivalent {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 6.99;
      case SubscriptionPlan.quarterly:
        return 17.99 / 3;
      case SubscriptionPlan.yearly:
        return 59.99 / 12;
    }
  }

  int get savingsPercentage {
    final monthlyPrice = 6.99;
    final monthlyEquivalentForPlan = monthlyEquivalent;
    final savings = ((monthlyPrice - monthlyEquivalentForPlan) / monthlyPrice) * 100;
    return savings.round();
  }

  String get savingsText {
    switch (this) {
      case SubscriptionPlan.monthly:
        return '';
      case SubscriptionPlan.quarterly:
        return 'Save $savingsPercentage%';
      case SubscriptionPlan.yearly:
        return 'Save $savingsPercentage%';
    }
  }

  String get planId {
    switch (this) {
      case SubscriptionPlan.monthly:
        return 'premium_monthly';
      case SubscriptionPlan.quarterly:
        return 'premium_quarterly';
      case SubscriptionPlan.yearly:
        return 'premium_yearly';
    }
  }
}