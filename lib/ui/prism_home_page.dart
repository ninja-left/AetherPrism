import 'dart:async';

import 'dart:io';

import 'package:flutter/material.dart';

import '../models/aether_profile.dart';
import '../services/aether_binary_resolver.dart';
import '../services/aether_launcher.dart';
import '../services/local_process_launcher.dart';
import '../services/profile_store.dart';
import '../services/retry_supervisor.dart';

class PrismHomePage extends StatefulWidget {
  const PrismHomePage({super.key});

  @override
  State<PrismHomePage> createState() => _PrismHomePageState();
}

class _PrismHomePageState extends State<PrismHomePage> {
  final AetherLauncher _launcher = LocalProcessLauncher();
  final ProfileStore _profileStore = ProfileStore();
  final RetrySupervisor _retrySupervisor = RetrySupervisor();
  final AetherBinaryResolver _binaryResolver = const AetherBinaryResolver();

  final TextEditingController _configController =
      TextEditingController(text: 'aether.toml');
  final TextEditingController _socksController =
      TextEditingController(text: '127.0.0.1:1819');
  final TextEditingController _peerController = TextEditingController();
  final TextEditingController _masquePeerController = TextEditingController();
  final TextEditingController _keepaliveController =
      TextEditingController(text: '5');
  final TextEditingController _stallController =
      TextEditingController(text: '20');
  final TextEditingController _importController = TextEditingController();

  final ScrollController _logScrollController = ScrollController();
  final List<String> _logs = <String>[];

  AetherProtocol _protocol = AetherProtocol.masque;
  AetherNoiseProfile _noiseProfile = AetherNoiseProfile.firewall;
  AetherScanMode _scanMode = AetherScanMode.balanced;
  AetherIpMode _ipMode = AetherIpMode.ipv4;
  bool _masqueHttp2 = false;
  bool _noWatchdog = false;
  bool _noDataCheck = false;
  bool _noProfileRetry = false;

  bool _running = false;
  bool _stopRequested = false;
  bool _autoRetryEnabled = true;
  String _status = 'Idle';
  String _binaryLabel = 'Bundled binary';
  String _binaryAsset = 'assets/runtime/...';
  int? _pid;

  StreamSubscription<String>? _logSub;
  StreamSubscription<ProcessEvent>? _eventSub;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _refreshBinaryMetadata();
    _restoreLastProfile();
  }

  Future<void> _refreshBinaryMetadata() async {
    final String label = _binaryResolver.describeCurrentTarget();
    final String asset = _binaryResolver.describeCurrentAsset();
    if (!mounted) return;
    setState(() {
      _binaryLabel = label;
      _binaryAsset = asset;
    });
  }

  @override
  void dispose() {
    _configController.dispose();
    _socksController.dispose();
    _peerController.dispose();
    _masquePeerController.dispose();
    _keepaliveController.dispose();
    _stallController.dispose();
    _importController.dispose();
    _logScrollController.dispose();
    _logSub?.cancel();
    _eventSub?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreLastProfile() async {
    final AetherProfile? profile = await _profileStore.load();
    if (!mounted || profile == null) {
      return;
    }
    _applyProfile(profile);
    setState(() {
      _status = 'Profile loaded';
    });
  }

  void _applyProfile(AetherProfile profile) {
    _protocol = profile.protocol;
    _socksController.text = profile.socksAddress;
    _noiseProfile = profile.noiseProfile;
    _scanMode = profile.scanMode;
    _ipMode = profile.ipMode;
    _masqueHttp2 = profile.masqueHttp2;
    _masquePeerController.text = profile.masqueH2Peer ?? '';
    _peerController.text = profile.peer ?? '';
    _configController.text = profile.configPath ?? _configController.text;
    _keepaliveController.text = profile.wgKeepalive?.toString() ?? '5';
    _stallController.text = profile.wgStall?.toString() ?? '20';
    _noWatchdog = profile.noWatchdog;
    _noDataCheck = profile.noDataCheck;
    _noProfileRetry = profile.noProfileRetry;
  }

  AetherProfile _buildProfile() {
    return AetherProfile(
      protocol: _protocol,
      socksAddress: _socksController.text.trim(),
      noiseProfile: _noiseProfile,
      scanMode: _scanMode,
      ipMode: _ipMode,
      masqueHttp2: _masqueHttp2,
      masqueH2Peer: _masquePeerController.text.trim().isEmpty
          ? null
          : _masquePeerController.text.trim(),
      peer: _peerController.text.trim().isEmpty
          ? null
          : _peerController.text.trim(),
      configPath: _configController.text.trim().isEmpty
          ? null
          : _configController.text.trim(),
      wgKeepalive: int.tryParse(_keepaliveController.text.trim()),
      wgStall: int.tryParse(_stallController.text.trim()),
      noWatchdog: _noWatchdog,
      noDataCheck: _noDataCheck,
      noProfileRetry: _noProfileRetry,
    );
  }

  Future<void> _saveProfile() async {
    final AetherProfile profile = _buildProfile();
    await _profileStore.save(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'Profile saved';
    });
  }

  Future<void> _exportProfile() async {
    final String raw = await _profileStore.exportJson(_buildProfile());
    _importController.text = raw;
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'Profile JSON copied to import box';
    });
  }

  Future<void> _importProfile() async {
    try {
      final AetherProfile profile = _profileStore.importJson(_importController.text);
      setState(() {
        _applyProfile(profile);
        _status = 'Profile imported';
      });
    } catch (e) {
      setState(() {
        _status = 'Import failed: $e';
      });
    }
  }

  Future<void> _start({bool preserveRetryState = false}) async {
    if (_running) return;

    if (!preserveRetryState) {
      _retrySupervisor.reset();
      _logs.clear();
    } else {
      _retrySupervisor.clearLogs();
    }
    _stopRequested = false;
    setState(() {
      _running = true;
      _status = 'Resolving bundled binary...';
      if (preserveRetryState) {
        _logs.add('--- retrying Aether ---');
      }
    });

    await _saveProfile();

    try {
      final File executable = await _binaryResolver.resolveExecutable();
      final AetherProfile profile = _buildProfile();
      final LaunchResult result = await _launcher.start(
        LaunchRequest(
          executablePath: executable.path,
          environment: profile.toEnvironment(),
          workingDirectory: '.',
        ),
      );

      _pid = result.pid;
      _status = 'Running';
      _logSub = result.logs.listen((String line) {
        _retrySupervisor.recordLog(line);
        if (!mounted) return;
        setState(() {
          _logs.add(line);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
          }
        });
      });

      _eventSub = result.events.listen((ProcessEvent event) async {
        if (!mounted) return;
        if (event.message != null) {
          setState(() {
            _logs.add(event.message!);
          });
        }

        if (event.type == ProcessEventType.exited) {
          _pid = null;
          final RetrySignal signal = _retrySupervisor.evaluateExit(
            exitCode: _parseExitCode(event.message),
            terminatedByUser: _stopRequested,
          );

          if (signal.shouldRetry && _autoRetryEnabled) {
            setState(() {
              _running = false;
              _status = 'Disconnected, retrying...';
            });
            _retryTimer?.cancel();
            _retryTimer = Timer(_retrySupervisor.retryDelay(), () async {
              if (!mounted || _stopRequested) return;
              await _start(preserveRetryState: true);
            });
          } else {
            setState(() {
              _running = false;
              _status = signal.reason;
            });
          }
        } else if (event.type == ProcessEventType.error) {
          setState(() {
            _status = event.message ?? 'Launcher error';
          });
        }
      });
    } catch (e) {
      setState(() {
        _running = false;
        _pid = null;
        _status = 'Start failed: $e';
      });
    }
  }

  int? _parseExitCode(String? message) {
    if (message == null) return null;
    final RegExpMatch? match = RegExp(r'code\s+(-?\d+)').firstMatch(message);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<void> _stop({bool force = false}) async {
    if (!_running) return;
    _stopRequested = true;
    _retryTimer?.cancel();
    setState(() {
      _status = 'Stopping...';
    });

    try {
      await _launcher.stop(force: force);
    } finally {
      await _logSub?.cancel();
      await _eventSub?.cancel();
      _logSub = null;
      _eventSub = null;
      if (!mounted) return;
      setState(() {
        _running = false;
        _pid = null;
        _status = force ? 'Stopped hard' : 'Stopped';
      });
    }
  }

  Future<void> _restart() async {
    await _stop();
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    final AetherProfile profile = _buildProfile();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aether Prism v1.0.7'),
        actions: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(_status, style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool wide = constraints.maxWidth >= 1100;
          final Widget controls = _controlsPanel(profile);
          final Widget logs = _logsPanel();
          final Widget summary = _summaryPanel(profile);

          if (wide) {
            return Row(
              children: <Widget>[
                Expanded(flex: 6, child: controls),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        summary,
                        const SizedBox(height: 12),
                        logs,
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                controls,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: summary,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: logs,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _controlsPanel(AetherProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _panel(
            title: 'Launcher',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Bundled binary: $_binaryLabel',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  _binaryAsset,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _configController,
                  label: 'Config path',
                  hint: 'aether.toml',
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _socksController,
                  label: 'SOCKS address',
                  hint: '127.0.0.1:1819',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Connection profile',
            child: Column(
              children: <Widget>[
                _dropdown(
                  label: 'Protocol',
                  value: _protocol,
                  items: AetherProtocol.values,
                  itemLabel: (AetherProtocol v) => v.label,
                  onChanged: (AetherProtocol? v) => setState(() => _protocol = v!),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: 'Noise profile',
                  value: _noiseProfile,
                  items: AetherNoiseProfile.values,
                  itemLabel: (AetherNoiseProfile v) => v.label,
                  onChanged: (AetherNoiseProfile? v) => setState(() => _noiseProfile = v!),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: 'Scan mode',
                  value: _scanMode,
                  items: AetherScanMode.values,
                  itemLabel: (AetherScanMode v) => v.label,
                  onChanged: (AetherScanMode? v) => setState(() => _scanMode = v!),
                ),
                const SizedBox(height: 12),
                _dropdown(
                  label: 'IP mode',
                  value: _ipMode,
                  items: AetherIpMode.values,
                  itemLabel: (AetherIpMode v) => v.label,
                  onChanged: (AetherIpMode? v) => setState(() => _ipMode = v!),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _masqueHttp2,
                  onChanged: (bool v) => setState(() => _masqueHttp2 = v),
                  title: const Text('Force MASQUE h2'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Advanced flags',
            child: Column(
              children: <Widget>[
                _field(
                  controller: _peerController,
                  label: 'Peer override',
                  hint: 'AETHER_PEER / AETHER_WG_PEER',
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _masquePeerController,
                  label: 'MASQUE h2 peer override',
                  hint: 'AETHER_MASQUE_H2_PEER',
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _field(
                        controller: _keepaliveController,
                        label: 'WG keepalive',
                        hint: '5',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _stallController,
                        label: 'WG stall',
                        hint: '20',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _noWatchdog,
                  onChanged: (bool v) => setState(() => _noWatchdog = v),
                  title: const Text('Disable watchdog'),
                ),
                SwitchListTile(
                  value: _noDataCheck,
                  onChanged: (bool v) => setState(() => _noDataCheck = v),
                  title: const Text('Disable scan data check'),
                ),
                SwitchListTile(
                  value: _noProfileRetry,
                  onChanged: (bool v) => setState(() => _noProfileRetry = v),
                  title: const Text('Disable profile retry'),
                ),
                SwitchListTile(
                  value: _autoRetryEnabled,
                  onChanged: (bool v) => setState(() => _autoRetryEnabled = v),
                  title: const Text('Auto retry on failure logs'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Controls',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton(
                  onPressed: _running ? null : _start,
                  child: const Text('Start'),
                ),
                FilledButton.tonal(
                  onPressed: _running ? _stop : null,
                  child: const Text('Stop'),
                ),
                OutlinedButton(
                  onPressed: _restart,
                  child: const Text('Restart'),
                ),
                OutlinedButton(
                  onPressed: _running ? () => _stop(force: true) : null,
                  child: const Text('Force stop'),
                ),
                OutlinedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save profile'),
                ),
                OutlinedButton(
                  onPressed: _exportProfile,
                  child: const Text('Export JSON'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Import JSON',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _importController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Paste profile JSON here',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _importProfile,
                  child: const Text('Import JSON'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _panel(
            title: 'Generated environment',
            child: SelectableText(profile.environmentPreview()),
          ),
        ],
      ),
    );
  }

  Widget _summaryPanel(AetherProfile profile) {
    return _panel(
      title: 'Current profile',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Protocol: ${profile.protocol.label}'),
          Text('Noise: ${profile.noiseProfile.label}'),
          Text('Scan: ${profile.scanMode.label}'),
          Text('IP: ${profile.ipMode.label}'),
          Text('SOCKS: ${profile.socksAddress}'),
          Text('Binary: $_binaryLabel'),
          Text('PID: ${_pid?.toString() ?? "-"}'),
        ],
      ),
    );
  }

  Widget _logsPanel() {
    return _panel(
      title: 'Logs',
      child: SizedBox(
        height: 420,
        child: ListView.builder(
          controller: _logScrollController,
          primary: false,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _logs.isEmpty ? 1 : _logs.length,
          itemBuilder: (BuildContext context, int index) {
            if (_logs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No logs yet.'),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _logs[index],
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map(
            (T item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
