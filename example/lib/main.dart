import 'package:flutter/material.dart';
import 'package:skywalking_dart/skywalking_dart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SkywalkingAgent.initFromEnvironment(
    defaultServiceName: 'flutter-native-demo',
    defaultNativeBackend: '127.0.0.1:11800',
    dartDefines: const {
      'SKYWALKING_AGENT_MODE': 'nativeFull',
      'SKYWALKING_METRICS_ENABLED': 'true',
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyWalking Native Demo',
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _status = 'Tap to send native trace + meter';

  Future<void> _sendSample() async {
    if (!SkywalkingAgent.isInitialized) {
      setState(() => _status = 'Agent not initialized');
      return;
    }
    try {
      final agent = SkywalkingAgent.instance;
      agent.nativeTracer.recordSpan(
        name: 'demo.button.tap',
        duration: const Duration(milliseconds: 5),
      );
      agent.meter?.addCounter('demo.taps', attributes: {'screen': 'home'});
      await agent.flush();
      setState(() => _status = 'Sent. Check Horizon DART layer for flutter-native-demo');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final backend = SkywalkingAgent.isInitialized
        ? SkywalkingAgent.instance.config.native.backendAddress
        : '(disabled)';
    return Scaffold(
      appBar: AppBar(title: const Text('Native Agent Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('gRPC → $backend', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: _sendSample, child: const Text('Send sample')),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
