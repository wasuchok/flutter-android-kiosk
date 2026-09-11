class WifiNetwork {
  final String ssid;
  final String? password;
  final String? username;

  const WifiNetwork({
    required this.ssid,
    this.password,
    this.username,
  });
}
