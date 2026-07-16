import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const AetherPrismApp());
}

class AetherPrismApp extends StatelessWidget {
  const AetherPrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aether Prism',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const PrismHomePage(),
    );
  }
}

enum AetherProtocol { masque, wg, gool }

enum AetherScanMode { turbo, balanced, thorough, stealth }

enum AetherNoiseProfile { firewall, gfw, balanced, aggressive, light, off }

enum AetherIpVersion { ipv4, ipv6, both }

extension AetherProtocolX on AetherProtocol {
  String get wireValue => switch (this) {
        AetherProtocol.masque => 'masque',
        AetherProtocol.wg => 'wg',
        AetherProtocol.gool => 'gool',
      };

  String get label => switch (this) {
        AetherProtocol.masque => 'MASQUE',
        AetherProtocol.wg => 'WireGuard',
        AetherProtocol.gool => 'Nested WireGuard (gool)',
      };
}

extension AetherScanModeX on AetherScanMode {
  String get wireValue => switch (this) {
        AetherScanMode.turbo => 'turbo',
        AetherScanMode.balanced => 'balanced',
        AetherScanMode.thorough => 'thorough',
        AetherScanMode.stealth => 'stealth',
      };
}

extension AetherNoiseProfileX on AetherNoiseProfile {
  String get wireValue => switch (this) {
        AetherNoiseProfile.firewall => 'firewall',
        AetherNoiseProfile.gfw => 'gfw',
        AetherNoiseProfile.balanced => 'balanced',
        AetherNoiseProfile.aggressive => 'aggressive',
        AetherNoiseProfile.light => 'light',
        AetherNoiseProfile.off => 'off',
      };
}

extension AetherIpVersionX on AetherIpVersion {
  String get wireValue => switch (this) {
        AetherIpVersion.ipv4 => 'ipv4',
        AetherIpVersion.ipv6 => 'ipv6',
        AetherIpVersion.both => 'both',
      };
}

class AetherProfile {
  AetherProfile({
    this.binaryPath = '',
    this.workingDirectory = '',
    this.protocol = AetherProtocol.masque,
    this.scanMode = AetherScanMode.balanced,
    this.noiseProfile = AetherNoiseProfile.firewall,
    this.ipVersion = AetherIpVersion.both,
    this.socksAddress = '127.0.0.1:1819',
    this.useMasqueHttp2 = false,
    this.masqueH2Peer = '',
    this.fixedPeer = '',
    this.configPath = '',
    this.wgKeepalive = '5',
    this.wgStall = '20',
    this.noWatchdog = false,
    this.noDataCheck = false,
    this.noProfileRetry = false,
  });

  String binaryPath;
  String workingDirectory;
  AetherProtocol protocol;
  AetherScanMode scanMode;
  AetherNoiseProfile noiseProfile;
  AetherIpVersion ipVersion;
  String socksAddress;
  bool useMasqueHttp2;
  String masqueH2Peer;
  String fixedPeer;
  String configPath;
  String wgKeepalive;
  String wgStall;
  bool noWatchdog;
  bool noDataCheck;
  bool noProfileRetry;

  Map<String, String> toEnvironment() {
    final env = <String, String>{
      'AETHER_PROTOCOL': protocol.wireValue,
      'AETHER_SCAN': scanMode.wireValue,
      'AETHER_NOIZE': noiseProfile.wireValue,
      'AETHER_IP': ipVersion.wireValue,
      'AETHER_SOCKS': socksAddress.trim(),
    };

    if (useMasqueHttp2) {
      env['AETHER_MASQUE_HTTP2'] = '1';
    }
    if (masqueH2Peer.trim().isNotEmpty) {
      env['AETHER_MASQUE_H2_PEER'] = masqueH2Peer.trim();
    }
    if (fixedPeer.trim().isNotEmpty) {
      env['AETHER_PEER'] = fixedPeer.trim();
      env['AETHER_WG_PEER'] = fixedPeer.trim();
    }
    if (configPath.trim().isNotEmpty) {
      env['AETHER_CONFIG'] = configPath.trim();
      env['AETHER_WG_CONFIG'] = configPath.trim();
      env['AETHER_MASQUE_CONFIG'] = configPath.trim();
    }
    if (wgKeepalive.trim().isNotEmpty) {
      env['AETHER_WG_KEEPALIVE'] = wgKeepalive.trim();
    }
    if (wgStall.trim().isNotEmpty) {
      env['AETHER_WG_STALL'] = wgStall.trim();
    }
    if (noWatchdog) {
      env['AETHER_NO_WATCHDOG'] = '1';
    }
    if (noDataCheck) {
      env['AETHER_WG_NO_DATA_CHECK'] = '1';
    }
    if (noProfileRetry) {
      env['AETHER_WG_NO_PROFILE_RETRY'] = '1';
    }

    return env;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'binaryPath': binaryPath,
        'workingDirectory': workingDirectory,
        'protocol': protocol.name,
        'scanMode': scanMode.name,
        'noiseProfile': noiseProfile.name,
        'ipVersion': ipVersion.name,
        'socksAddress': socksAddress,
        'useMasqueHttp2': useMasqueHttp2,
        'masqueH2Peer': masqueH2Peer,
        'fixedPeer': fixedPeer,
        'configPath': configPath,
        'wgKeepalive': wgKeepalive,
        'wgStall': wgStall,
        'noWatchdog': noWatchdog,
        'noDataCheck': noDataCheck,
        'noProfileRetry': noProfileRetry,
      };

  static AetherProfile fromJson(Map<String, dynamic> json) {
    return AetherProfile(
      binaryPath: json['binaryPath'] as String? ?? '',
      workingDirectory: json['workingDirectory'] as String? ?? '',
      protocol: AetherProtocol.values.firstWhere(
        (p) => p.name == json['protocol'],
        orElse: () => AetherProtocol.masque,
      ),
      scanMode: AetherScanMode.values.firstWhere(
        (m) => m.name == json['scanMode'],
        orElse: () => AetherScanMode.balanced,
      ),
      noiseProfile: AetherNoiseProfile.values.firstWhere(
        (n) => n.name == json['noiseProfile'],
        orElse: () => AetherNoiseProfile.firewall,
      ),
      ipVersion: AetherIpVersion.values.firstWhere(
        (ip) => ip.name == json['ipVersion'],
        orElse: () => AetherIpVersion.both,
      ),
      socksAddress: json['socksAddress'] as String? ?? '127.0.0.1:1819',
      useMasqueHttp2: json['useMasqueHttp2'] as bool? ?? false,
      masqueH2Peer: json['masqueH2Peer'] as String? ?? '',
      fixedPeer: json['fixedPeer'] as String? ?? '',
      configPath: json['configPath'] as String? ?? '',
      wgKeepalive: json['wgKeepalive'] as String? ?? '5',
      wgStall: json['wgStall'] as String? ?? '20',
      noWatchdog: json['noWatchdog'] as bool? ?? false,
      noDataCheck: json['noDataCheck'] as bool? ?? false,
      noProfileRetry: json['noProfileRetry'] as bool? ?? false,
    );
  }
}

class AetherSession extends ChangeNotifier {
  AetherSession();

  final AetherProfile profile = AetherProfile();
  final List<String> logs = <String>[];
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _starting = false;
  bool _saving = false;
  bool _loading = false;
  String? _status = 'Idle';

  bool get isRunning => _process != null;
  bool get isBusy => _starting || _saving || _loading;
  String? get status => _status;

  Future<void> loadSavedProfile() async {
    _loading = true;
    notifyListeners();

    try {
      final file = await _profileFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = AetherProfile.fromJson(data);
        _copyProfile(loaded);
        _status = 'Loaded saved profile';
        _appendLog('Loaded profile from ${file.path}');
      }
    } catch (e) {
      _appendLog('Profile load failed: $e');
      _status = 'Profile load failed';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _copyProfile(AetherProfile other) {
    profile
      ..binaryPath = other.binaryPath
      ..workingDirectory = other.workingDirectory
      ..protocol = other.protocol
      ..scanMode = other.scanMode
      ..noiseProfile = other.noiseProfile
      ..ipVersion = other.ipVersion
      ..socksAddress = other.socksAddress
      ..useMasqueHttp2 = other.useMasqueHttp2
      ..masqueH2Peer = other.masqueH2Peer
      ..fixedPeer = other.fixedPeer
      ..configPath = other.configPath
      ..wgKeepalive = other.wgKeepalive
      ..wgStall = other.wgStall
      ..noWatchdog = other.noWatchdog
      ..noDataCheck = other.noDataCheck
      ..noProfileRetry = other.noProfileRetry;
  }

  void applyPreset(AetherProtocol protocol) {
    switch (protocol) {
      case AetherProtocol.masque:
        profile.protocol = AetherProtocol.masque;
        profile.scanMode = AetherScanMode.balanced;
        profile.noiseProfile = AetherNoiseProfile.firewall;
        profile.useMasqueHttp2 = false;
        break;
      case AetherProtocol.wg:
        profile.protocol = AetherProtocol.wg;
        profile.scanMode = AetherScanMode.thorough;
        profile.noiseProfile = AetherNoiseProfile.balanced;
        profile.wgKeepalive = '5';
        profile.wgStall = '20';
        break;
      case AetherProtocol.gool:
        profile.protocol = AetherProtocol.gool;
        profile.scanMode = AetherScanMode.thorough;
        profile.noiseProfile = AetherNoiseProfile.aggressive;
        profile.wgKeepalive = '5';
        profile.wgStall = '20';
        break;
    }
    _status = 'Preset applied: ${protocol.label}';
    notifyListeners();
  }

  void _appendLog(String line) {
    final stamp = DateTime.now().toIso8601String().split('.').first;
    logs.add('[$stamp] $line');
    if (logs.length > 500) {
      logs.removeRange(0, logs.length - 500);
    }
    notifyListeners();
  }

  Future<File> _profileFile() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'aether_prism_profile.json'));
  }

  Future<void> saveProfile() async {
    _saving = true;
    notifyListeners();
    try {
      final file = await _profileFile();
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(profile.toJson()));
      _status = 'Profile saved';
      _appendLog('Saved profile to ${file.path}');
    } catch (e) {
      _status = 'Save failed';
      _appendLog('Profile save failed: $e');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (isRunning || _starting) return;

    final binary = profile.binaryPath.trim();
    if (binary.isEmpty) {
      _status = 'Set the Aether binary path first';
      notifyListeners();
      return;
    }

    _starting = true;
    _status = 'Starting...';
    notifyListeners();

    try {
      final workingDirectory = profile.workingDirectory.trim().isEmpty ? null : profile.workingDirectory.trim();
      final env = profile.toEnvironment();
      _appendLog('Launching $binary');
      _appendLog('Env: ${env.entries.map((e) => '${e.key}=${e.value}').join(' ')}');

      _process = await Process.start(
        binary,
        const <String>[],
        workingDirectory: workingDirectory,
        environment: env,
        runInShell: false,
      );

      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLog(line));

      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLog('ERR: $line'));

      _status = 'Running';
      _process!.exitCode.then((code) {
        _appendLog('Process exited with code $code');
        _status = 'Stopped';
        _cleanupProcess();
        notifyListeners();
      });
    } catch (e) {
      _status = 'Start failed';
      _appendLog('Failed to launch: $e');
      _cleanupProcess();
    } finally {
      _starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    if (_process == null) return;
    _status = 'Stopping...';
    notifyListeners();

    try {
      _process!.kill(ProcessSignal.sigterm);
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_process != null) {
        _process!.kill(ProcessSignal.sigkill);
      }
      _appendLog('Stop requested');
    } catch (e) {
      _appendLog('Stop failed: $e');
    } finally {
      _cleanupProcess();
      _status = 'Stopped';
      notifyListeners();
    }
  }

  void _cleanupProcess() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _process = null;
  }
}

class PrismHomePage extends StatefulWidget {
  const PrismHomePage({super.key});

  @override
  State<PrismHomePage> createState() => _PrismHomePageState();
}

class _PrismHomePageState extends State<PrismHomePage> {
  final AetherSession session = AetherSession();

  final TextEditingController binaryController = TextEditingController();
  final TextEditingController workDirController = TextEditingController();
  final TextEditingController socksController = TextEditingController();
  final TextEditingController fixedPeerController = TextEditingController();
  final TextEditingController configController = TextEditingController();
  final TextEditingController masquePeerController = TextEditingController();
  final TextEditingController keepaliveController = TextEditingController();
  final TextEditingController stallController = TextEditingController();
  final ScrollController logScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    session.addListener(_onSessionChanged);
    _syncControllersFromProfile();
    unawaited(() async {
      await session.loadSavedProfile();
      _syncControllersFromProfile();
    }());
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    session.dispose();
    binaryController.dispose();
    workDirController.dispose();
    socksController.dispose();
    fixedPeerController.dispose();
    configController.dispose();
    masquePeerController.dispose();
    keepaliveController.dispose();
    stallController.dispose();
    logScroll.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (logScroll.hasClients) {
        logScroll.jumpTo(logScroll.position.maxScrollExtent);
      }
    });
  }

  void _syncControllersFromProfile() {
    binaryController.text = session.profile.binaryPath;
    workDirController.text = session.profile.workingDirectory;
    socksController.text = session.profile.socksAddress;
    fixedPeerController.text = session.profile.fixedPeer;
    configController.text = session.profile.configPath;
    masquePeerController.text = session.profile.masqueH2Peer;
    keepaliveController.text = session.profile.wgKeepalive;
    stallController.text = session.profile.wgStall;
  }

  void _updateFromFields() {
    session.profile
      ..binaryPath = binaryController.text
      ..workingDirectory = workDirController.text
      ..socksAddress = socksController.text
      ..fixedPeer = fixedPeerController.text
      ..configPath = configController.text
      ..masqueH2Peer = masquePeerController.text
      ..wgKeepalive = keepaliveController.text
      ..wgStall = stallController.text;
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    bool dense = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: dense,
        ),
        onChanged: (_) => session.notifyListeners(),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) labelOf,
    required void Function(T) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values
            .map((e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(labelOf(e)),
                ))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateFromFields();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aether Prism'),
        actions: [
          IconButton(
            tooltip: 'Save profile',
            onPressed: session.isBusy ? null : session.saveProfile,
            icon: const Icon(Icons.save_outlined),
          ),
          IconButton(
            tooltip: 'Load profile',
            onPressed: session.isBusy
                ? null
                : () async {
                    await session.loadSavedProfile();
                    _syncControllersFromProfile();
                  },
            icon: const Icon(Icons.folder_open_outlined),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Core launcher'),
                    _textField(label: 'Aether binary path', controller: binaryController, hint: '/path/to/aether'),
                    _textField(label: 'Working directory', controller: workDirController, hint: 'Optional'),
                    _textField(label: 'SOCKS listen address', controller: socksController, hint: '127.0.0.1:1819'),
                    _sectionTitle('Profile'),
                    _dropdown<AetherProtocol>(
                      label: 'Protocol',
                      value: session.profile.protocol,
                      values: AetherProtocol.values,
                      labelOf: (v) => v.label,
                      onChanged: (v) {
                        session.profile.protocol = v;
                        session.notifyListeners();
                      },
                    ),
                    _dropdown<AetherScanMode>(
                      label: 'Scan mode',
                      value: session.profile.scanMode,
                      values: AetherScanMode.values,
                      labelOf: (v) => v.wireValue,
                      onChanged: (v) {
                        session.profile.scanMode = v;
                        session.notifyListeners();
                      },
                    ),
                    _dropdown<AetherNoiseProfile>(
                      label: 'Noise profile',
                      value: session.profile.noiseProfile,
                      values: AetherNoiseProfile.values,
                      labelOf: (v) => v.wireValue,
                      onChanged: (v) {
                        session.profile.noiseProfile = v;
                        session.notifyListeners();
                      },
                    ),
                    _dropdown<AetherIpVersion>(
                      label: 'IP version',
                      value: session.profile.ipVersion,
                      values: AetherIpVersion.values,
                      labelOf: (v) => v.wireValue,
                      onChanged: (v) {
                        session.profile.ipVersion = v;
                        session.notifyListeners();
                      },
                    ),
                    _toggle('Use MASQUE HTTP/2', session.profile.useMasqueHttp2, (v) {
                      session.profile.useMasqueHttp2 = v;
                      session.notifyListeners();
                    }),
                    _textField(label: 'MASQUE H2 peer override', controller: masquePeerController, hint: 'Optional'),
                    _textField(label: 'Fixed peer override', controller: fixedPeerController, hint: 'Optional'),
                    _textField(label: 'Config path', controller: configController, hint: 'Optional'),
                    _textField(label: 'WG keepalive', controller: keepaliveController, hint: '5'),
                    _textField(label: 'WG stall', controller: stallController, hint: '20'),
                    _toggle('Disable watchdog', session.profile.noWatchdog, (v) {
                      session.profile.noWatchdog = v;
                      session.notifyListeners();
                    }),
                    _toggle('Disable data check', session.profile.noDataCheck, (v) {
                      session.profile.noDataCheck = v;
                      session.notifyListeners();
                    }),
                    _toggle('Disable profile retry', session.profile.noProfileRetry, (v) {
                      session.profile.noProfileRetry = v;
                      session.notifyListeners();
                    }),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: session.isBusy
                              ? null
                              : () {
                                  session.applyPreset(AetherProtocol.masque);
                                  _syncControllersFromProfile();
                                },
                          child: const Text('MASQUE preset'),
                        ),
                        FilledButton(
                          onPressed: session.isBusy
                              ? null
                              : () {
                                  session.applyPreset(AetherProtocol.wg);
                                  _syncControllersFromProfile();
                                },
                          child: const Text('WireGuard preset'),
                        ),
                        FilledButton(
                          onPressed: session.isBusy
                              ? null
                              : () {
                                  session.applyPreset(AetherProtocol.gool);
                                  _syncControllersFromProfile();
                                },
                          child: const Text('gool preset'),
                        ),
                        FilledButton.icon(
                          onPressed: session.isRunning ? null : session.start,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                        ),
                        OutlinedButton.icon(
                          onPressed: session.isRunning ? session.stop : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${session.status ?? 'unknown'}'),
                            const SizedBox(height: 8),
                            Text('Running: ${session.isRunning ? 'yes' : 'no'}'),
                            const SizedBox(height: 8),
                            Text('Binary: ${session.profile.binaryPath.isEmpty ? 'unset' : session.profile.binaryPath}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: logScroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: session.logs.length,
                      itemBuilder: (context, index) {
                        return SelectableText(
                          session.logs[index],
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
