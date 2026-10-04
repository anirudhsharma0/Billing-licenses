class UpdateConfig {
  // Current app version (update this when releasing new versions)
  static const String currentVersion = '1.0.1';
  static const int currentBuildNumber = 2;

  // GitHub repository details
  static const String githubRepoOwner = 'anirudhsharma0';
  static const String githubRepoName = 'Billing-licenses';

  // Direct version manifest URL on GitHub raw content
  static const String versionJsonUrl =
      'https://raw.githubusercontent.com/anirudhsharma0/Billing-licenses/main/version.json';

  // GitHub Latest Release API endpoint
  static const String githubReleasesApiUrl =
      'https://api.github.com/repos/anirudhsharma0/Billing-licenses/releases/latest';
}
