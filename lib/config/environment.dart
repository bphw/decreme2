enum BuildFlavor {
  development,
  production,
}

class Environment {
  static late BuildFlavor flavor;

  static bool get isDevelopment => flavor == BuildFlavor.development;
  static bool get isProduction => flavor == BuildFlavor.production;
} 