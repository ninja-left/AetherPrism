import 'package:flutter_test/flutter_test.dart';
import 'package:aetherprism/models/aether_profile.dart';

void main() {
  test('profile env mapping includes the core flags', () {
    const profile = AetherProfile(
      protocol: AetherProtocol.masque,
      socksAddress: '127.0.0.1:1819',
      noiseProfile: AetherNoiseProfile.firewall,
      scanMode: AetherScanMode.balanced,
      ipMode: AetherIpMode.ipv4,
      masqueHttp2: true,
      noWatchdog: true,
    );

    final env = profile.toEnvironment();

    expect(env['AETHER_PROTOCOL'], 'masque');
    expect(env['AETHER_SOCKS'], '127.0.0.1:1819');
    expect(env['AETHER_MASQUE_HTTP2'], '1');
    expect(env['AETHER_NO_WATCHDOG'], '1');
  });
}
