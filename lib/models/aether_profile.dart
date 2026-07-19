enum AetherProtocol { masque, wireguard, gool }

enum AetherNoiseProfile { firewall, gfw, balanced, aggressive, light, off }

enum AetherScanMode { turbo, balanced, thorough, stealth }

enum AetherIpMode { ipv4, ipv6, both }

extension AetherProtocolLabel on AetherProtocol {
  String get label => switch (this) {
        AetherProtocol.masque => 'MASQUE',
        AetherProtocol.wireguard => 'WireGuard',
        AetherProtocol.gool => 'Nested WireGuard (gool)',
      };

  String get envValue => switch (this) {
        AetherProtocol.masque => 'masque',
        AetherProtocol.wireguard => 'wg',
        AetherProtocol.gool => 'gool',
      };
}

extension AetherNoiseProfileLabel on AetherNoiseProfile {
  String get label => switch (this) {
        AetherNoiseProfile.firewall => 'firewall',
        AetherNoiseProfile.gfw => 'gfw',
        AetherNoiseProfile.balanced => 'balanced',
        AetherNoiseProfile.aggressive => 'aggressive',
        AetherNoiseProfile.light => 'light',
        AetherNoiseProfile.off => 'off',
      };

  String get envValue => label;
}

extension AetherScanModeLabel on AetherScanMode {
  String get label => switch (this) {
        AetherScanMode.turbo => 'turbo',
        AetherScanMode.balanced => 'balanced',
        AetherScanMode.thorough => 'thorough',
        AetherScanMode.stealth => 'stealth',
      };

  String get envValue => label;
}

extension AetherIpModeLabel on AetherIpMode {
  String get label => switch (this) {
        AetherIpMode.ipv4 => 'ipv4',
        AetherIpMode.ipv6 => 'ipv6',
        AetherIpMode.both => 'both',
      };

  String get envValue => label;
}

class AetherProfile {
  const AetherProfile({
    required this.protocol,
    required this.socksAddress,
    required this.noiseProfile,
    required this.scanMode,
    required this.ipMode,
    required this.masqueHttp2,
    this.masqueH2Peer,
    this.peer,
    this.configPath,
    this.wgKeepalive,
    this.wgStall,
    this.noWatchdog = false,
    this.noDataCheck = false,
    this.noProfileRetry = false,
  });

  final AetherProtocol protocol;
  final String socksAddress;
  final AetherNoiseProfile noiseProfile;
  final AetherScanMode scanMode;
  final AetherIpMode ipMode;
  final bool masqueHttp2;
  final String? masqueH2Peer;
  final String? peer;
  final String? configPath;
  final int? wgKeepalive;
  final int? wgStall;
  final bool noWatchdog;
  final bool noDataCheck;
  final bool noProfileRetry;

  Map<String, String> toEnvironment() {
    final Map<String, String> env = <String, String>{
      'AETHER_PROTOCOL': protocol.envValue,
      'AETHER_SOCKS': socksAddress,
      'AETHER_NOIZE': noiseProfile.envValue,
      'AETHER_SCAN': scanMode.envValue,
      'AETHER_IP': ipMode.envValue,
      'AETHER_MASQUE_HTTP2': masqueHttp2 ? '1' : '0',
      'AETHER_NO_WATCHDOG': noWatchdog ? '1' : '0',
      'AETHER_WG_NO_DATA_CHECK': noDataCheck ? '1' : '0',
      'AETHER_WG_NO_PROFILE_RETRY': noProfileRetry ? '1' : '0',
    };

    if (masqueH2Peer != null && masqueH2Peer!.isNotEmpty) {
      env['AETHER_MASQUE_H2_PEER'] = masqueH2Peer!;
    }
    if (peer != null && peer!.isNotEmpty) {
      env['AETHER_PEER'] = peer!;
      env['AETHER_WG_PEER'] = peer!;
    }
    if (configPath != null && configPath!.isNotEmpty) {
      env['AETHER_CONFIG'] = configPath!;
      env['AETHER_WG_CONFIG'] = configPath!;
      env['AETHER_MASQUE_CONFIG'] = configPath!;
    }
    if (wgKeepalive != null) {
      env['AETHER_WG_KEEPALIVE'] = wgKeepalive.toString();
    }
    if (wgStall != null) {
      env['AETHER_WG_STALL'] = wgStall.toString();
    }

    return env;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'protocol': protocol.name,
        'socksAddress': socksAddress,
        'noiseProfile': noiseProfile.name,
        'scanMode': scanMode.name,
        'ipMode': ipMode.name,
        'masqueHttp2': masqueHttp2,
        'masqueH2Peer': masqueH2Peer,
        'peer': peer,
        'configPath': configPath,
        'wgKeepalive': wgKeepalive,
        'wgStall': wgStall,
        'noWatchdog': noWatchdog,
        'noDataCheck': noDataCheck,
        'noProfileRetry': noProfileRetry,
      };

  factory AetherProfile.fromJson(Map<String, Object?> json) {
    return AetherProfile(
      protocol: AetherProtocol.values.byName(json['protocol'] as String),
      socksAddress: json['socksAddress'] as String,
      noiseProfile:
          AetherNoiseProfile.values.byName(json['noiseProfile'] as String),
      scanMode: AetherScanMode.values.byName(json['scanMode'] as String),
      ipMode: AetherIpMode.values.byName(json['ipMode'] as String),
      masqueHttp2: json['masqueHttp2'] as bool? ?? false,
      masqueH2Peer: json['masqueH2Peer'] as String?,
      peer: json['peer'] as String?,
      configPath: json['configPath'] as String?,
      wgKeepalive: (json['wgKeepalive'] as num?)?.toInt(),
      wgStall: (json['wgStall'] as num?)?.toInt(),
      noWatchdog: json['noWatchdog'] as bool? ?? false,
      noDataCheck: json['noDataCheck'] as bool? ?? false,
      noProfileRetry: json['noProfileRetry'] as bool? ?? false,
    );
  }

  String environmentPreview() {
    final entries = toEnvironment().entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key}=${e.value}').join('\n');
  }
}
