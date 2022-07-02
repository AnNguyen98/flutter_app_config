enum Environments {
  development,
  production,
  staging,
}

extension En on Environments {
  bool get isDevelopment => this == Environments.development;
  bool get isProduction => this == Environments.production;
  bool get isStaging => this == Environments.staging;

  FlavorValues get values {
    return FlavorValues(baseUrl: '');
  }

  String get baseUrl {
    if (isDevelopment) {
      return 'https://development.com';
    } else if (isStaging) {
      return 'https://staging.com';
    }
    return 'https://production.com';
  }
}

class FlavorValues {
  FlavorValues({
    required this.baseUrl,
  });

  final String baseUrl;
  //Add other flavor specific values, e.g database name
}
