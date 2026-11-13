import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../core/theme.dart';
import '../../core/toolkit_utils.dart';

class NetworkDoctorPage extends StatefulWidget {
  const NetworkDoctorPage({super.key, this.active = true});

  final bool active;

  @override
  State<NetworkDoctorPage> createState() => _NetworkDoctorPageState();
}

class _NetworkDoctorPageState extends State<NetworkDoctorPage> {
  final _network = NetworkInfo();
  final _domain = TextEditingController();
  final _wifiName = TextEditingController();
  final _output = StringBuffer();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _refreshTimer;
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.none];
  String? _ip;
  String? _gateway;
  String? _subnet;
  String? _bssid;
  String? _publicIp;
  String? _error;
  bool _busy = false;
  bool _publicIpRequested = false;

  bool get _online =>
      _connectivity.any((result) => result != ConnectivityResult.none);

  @override
  void initState() {
    super.initState();
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(covariant NetworkDoctorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) {
        _activate();
      } else {
        _refreshTimer?.cancel();
        _refreshTimer = null;
        _connectivitySubscription?.cancel();
        _connectivitySubscription = null;
      }
    }
  }

  void _activate() {
    _watchConnectivity();
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshNetwork();
    });
  }

  Future<void> _watchConnectivity() async {
    try {
      _connectivity = await Connectivity().checkConnectivity();
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((results) {
        if (!mounted) return;
        final wasOnline = _online;
        setState(() => _connectivity = results);
        _refreshNetwork();
        if (!wasOnline &&
            results.any((item) => item != ConnectivityResult.none)) {
          _publicIpRequested = false;
        }
      }, onError: (Object error) {
        if (mounted) setState(() => _error = 'Connectivity status: $error');
      });
      if (mounted) setState(() {});
      await _refreshNetwork();
    } catch (error) {
      if (mounted) setState(() => _error = 'Connectivity unavailable: $error');
    }
  }

  Future<void> _refreshNetwork() async {
    if (_busy) return;
    _busy = true;
    try {
      final values = await Future.wait<(String?, Object?)>([
        _safeNetworkValue(_network.getWifiIP),
        _safeNetworkValue(_network.getWifiGatewayIP),
        _safeNetworkValue(_network.getWifiSubmask),
        _safeNetworkValue(_network.getWifiBSSID),
      ]);
      if (!mounted) return;
      setState(() {
        _ip = values[0].$1;
        _gateway = values[1].$1;
        _subnet = values[2].$1;
        _bssid = values[3].$1;
        final failure = values.map((value) => value.$2).whereType<Object>();
        _error = failure.isEmpty
            ? null
            : 'Some local adapter details are unavailable: ${failure.first}';
      });
      if (_online && !_publicIpRequested) {
        _publicIpRequested = true;
        await _fetchPublicIp();
      } else if (!_online && mounted) {
        setState(() => _publicIp = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not refresh network data: $error');
      }
    } finally {
      _busy = false;
    }
  }

  Future<(String?, Object?)> _safeNetworkValue(
    Future<String?> Function() read,
  ) async {
    try {
      return (await read(), null);
    } catch (error) {
      return (null, error);
    }
  }

  Future<void> _fetchPublicIp() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final request = await client
          .getUrl(Uri.https('api.ipify.org', '/'))
          .timeout(const Duration(seconds: 5));
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
            'Public IP service returned ${response.statusCode}');
      }
      final value =
          (await response.transform(const SystemEncoding().decoder).join())
              .trim();
      if (value.isEmpty) {
        throw const FormatException('Empty public IP response');
      }
      if (mounted) setState(() => _publicIp = value);
    } catch (error) {
      if (mounted) {
        setState(() {
          _publicIp = null;
          _error = 'Public IP lookup failed: $error';
        });
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    _domain.dispose();
    _wifiName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
        title: 'Network Doctor',
        subtitle: 'Live adapter details and network diagnostic tools',
        children: [
          Text('Diagnostic Output',
              style: Theme.of(context).textTheme.titleLarge),
          TerminalPanel(
            text: _output.isEmpty
                ? 'Network data refreshes every 5 seconds.\n'
                    'Ping: ping 8.8.8.8\n'
                    'DNS: nslookup <domain>\n'
                    'Traceroute: ${Platform.isWindows ? 'tracert' : 'traceroute'} 8.8.8.8'
                : _output.toString(),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    _online ? Icons.wifi : Icons.wifi_off,
                    color: _online ? ToolkitColors.primary : Colors.orange,
                  ),
                  title: Text(_online ? 'Connected' : 'Disconnected'),
                  subtitle: Text(
                    _connectivity.map(_connectionName).join(', '),
                  ),
                  trailing: IconButton(
                    onPressed: _refreshNetwork,
                    tooltip: 'Refresh now',
                    icon: const Icon(Icons.refresh),
                  ),
                ),
                _info('Local IP', _ip),
                _info('Gateway', _gateway),
                _info('Subnet', _subnet),
                _info('Wi-Fi BSSID (access-point MAC)', _bssid),
                _info('Public IP', _publicIp),
              ],
            ),
          ),
          if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(_error!),
                trailing: IconButton(
                  onPressed: () => setState(() => _error = null),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          Text('Diagnostics', style: Theme.of(context).textTheme.titleLarge),
          _DiagnosticButton(
            title: 'Ping public DNS',
            command: 'ping 8.8.8.8',
            onPressed: () => _runDiagnostic(
              'Ping 8.8.8.8',
              'ping',
              Platform.isWindows
                  ? ['-n', '4', '8.8.8.8']
                  : ['-c', '4', '8.8.8.8'],
              displayCommand: 'ping 8.8.8.8',
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DNS Lookup'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _domain,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Domain name (e.g. example.com)',
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _lookupDomain,
                        icon: const Icon(Icons.search),
                        label: const Text('Lookup'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final domain = _validatedDomain();
                          if (domain != null) {
                            copyText(context, 'nslookup $domain');
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy nslookup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _DiagnosticButton(
            title: 'Test default gateway',
            command:
                _gateway == null ? 'Gateway unavailable' : 'ping $_gateway',
            onPressed: _gateway == null
                ? null
                : () => _runDiagnostic(
                      'Gateway test',
                      'ping',
                      Platform.isWindows
                          ? ['-n', '4', _gateway!]
                          : ['-c', '4', _gateway!],
                      displayCommand: 'ping $_gateway',
                    ),
          ),
          _DiagnosticButton(
            title: 'Traceroute to 8.8.8.8',
            command:
                Platform.isWindows ? 'tracert 8.8.8.8' : 'traceroute 8.8.8.8',
            onPressed: () => _runDiagnostic(
              'Traceroute',
              Platform.isWindows ? 'tracert' : 'traceroute',
              ['8.8.8.8'],
              displayCommand:
                  '${Platform.isWindows ? 'tracert' : 'traceroute'} 8.8.8.8',
            ),
          ),
          Text('Wi-Fi Tools', style: Theme.of(context).textTheme.titleLarge),
          _DiagnosticButton(
            title: 'Show saved Wi-Fi profiles',
            command: 'netsh wlan show profiles',
            onPressed: () => copyText(context, 'netsh wlan show profiles'),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Inspect a saved Wi-Fi profile'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _wifiName,
                    decoration:
                        const InputDecoration(labelText: 'Profile name'),
                    onSubmitted: (_) => _copyWifiCommand(),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _copyWifiCommand,
                    icon: const Icon(Icons.copy),
                    label: const Text('Generate command'),
                  ),
                  const Text(
                    'Run only on a device and profile you are authorized to administer.',
                    style: TextStyle(color: ToolkitColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          _DiagnosticButton(
            title: 'Speed test',
            command: 'https://fast.com',
            onPressed: () => copyText(context, 'https://fast.com'),
          ),
          const SizedBox(height: 8),
        ],
      );

  Widget _info(String title, String? value) => ListTile(
        dense: true,
        title: Text(title),
        trailing: Text(
          value ?? 'Unavailable',
          textAlign: TextAlign.end,
          style: const TextStyle(color: ToolkitColors.muted),
        ),
      );

  String _connectionName(ConnectivityResult result) => switch (result) {
        ConnectivityResult.wifi => 'Wi-Fi',
        ConnectivityResult.ethernet => 'Ethernet',
        ConnectivityResult.mobile => 'Mobile data',
        ConnectivityResult.vpn => 'VPN',
        ConnectivityResult.bluetooth => 'Bluetooth',
        ConnectivityResult.satellite => 'Satellite',
        ConnectivityResult.other => 'Other network',
        ConnectivityResult.none => 'No network',
      };

  String? _validatedDomain() {
    final value = _domain.text.trim();
    final valid = RegExp(
      r'^(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(?:\.(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?))*$',
    ).hasMatch(value);
    if (!valid) {
      showToolkitMessage(context, 'Enter a valid domain name.');
      return null;
    }
    return value;
  }

  Future<void> _lookupDomain() async {
    final domain = _validatedDomain();
    if (domain == null) return;
    setState(() => _output
      ..clear()
      ..write('nslookup $domain\nResolving…'));
    try {
      final addresses = await InternetAddress.lookup(domain)
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _output
        ..clear()
        ..write(
          'nslookup $domain\n${addresses.map((address) => address.address).join('\n')}',
        ));
    } catch (error) {
      if (mounted) {
        setState(() => _output
          ..clear()
          ..write('nslookup $domain\n$error'));
      }
    }
  }

  Future<void> _runDiagnostic(
    String title,
    String executable,
    List<String> arguments, {
    required String displayCommand,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _output
        ..clear()
        ..write('$displayCommand\nRunning…');
    });
    try {
      final result = await Process.run(executable, arguments)
          .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _output
          ..clear()
          ..write(
            '$displayCommand\n${result.stdout}\n${result.stderr}\nExit code: ${result.exitCode}',
          );
      });
    } on ProcessException catch (error) {
      if (mounted) {
        setState(() => _output
          ..clear()
          ..write('$displayCommand\n$executable is unavailable: $error'));
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _output
          ..clear()
          ..write(
              '$displayCommand\nTimed out. Try running this command locally.'));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _output
          ..clear()
          ..write('$title failed: $error'));
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _copyWifiCommand() async {
    final name = _wifiName.text.trim();
    if (name.isEmpty || RegExp(r'["%&|<>!\r\n]').hasMatch(name)) {
      showToolkitMessage(
        context,
        'Enter a profile name without quotes, shell operators, or line breaks.',
      );
      return;
    }
    await copyText(context, 'netsh wlan show profile name="$name" key=clear');
  }
}

class _DiagnosticButton extends StatelessWidget {
  const _DiagnosticButton({
    required this.title,
    required this.command,
    required this.onPressed,
  });

  final String title;
  final String command;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          subtitle: Text(command),
          trailing: IconButton(
            tooltip: 'Run diagnostic',
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow),
          ),
        ),
      );
}
