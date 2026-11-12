import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/bridge/native_bridge.dart';
import '../../core/bridge/permission_status_model.dart';
import '../../core/i18n/app_localizations.dart';
import '../recordings/ui/home_screen.dart';
import 'widgets/permission_step_card.dart';
import 'widgets/restricted_settings_guide.dart';

class SetupWizardScreen extends StatefulWidget {
  final NativeBridge bridge;

  const SetupWizardScreen({super.key, required this.bridge});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen>
    with WidgetsBindingObserver {
  PermissionStatusModel _status = PermissionStatusModel.initial();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify status whenever the user returns from system settings
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final status = await widget.bridge.getPermissionsStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestRuntimePermissions() async {
    await [
      Permission.microphone,
      Permission.phone,
      Permission.notification,
    ].request();

    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('setup_wizard_appbar'))),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.25),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Record Call',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('setup_steps_intro'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Алхам 1: Микрофон, Утас, Мэдэгдэл
                        PermissionStepCard(
                          stepNumber: 1,
                          title: context.tr('setup_wizard_step1_title'),
                          description: context.tr('setup_wizard_step1_desc'),
                          isCompleted: _status.areCorePermissionsGranted,
                          child: _status.areCorePermissionsGranted
                              ? const SizedBox.shrink()
                              : FilledButton.icon(
                                  onPressed: _requestRuntimePermissions,
                                  icon: const Icon(Icons.security, size: 18),
                                  label: Text(
                                    context.tr('grant_permission_btn'),
                                  ),
                                ),
                        ),

                        // Алхам 2: Accessibility Үйлчилгээ (VoIP дуудлага барихад)
                        PermissionStepCard(
                          stepNumber: 2,
                          title: context.tr('setup_wizard_step2_title'),
                          description: context.tr('setup_wizard_step2_desc'),
                          isCompleted: _status.accessibility,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!_status.accessibility) ...[
                                RestrictedSettingsGuide(
                                  onOpenAppInfo: () =>
                                      widget.bridge.openAppDetailsSettings(),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () =>
                                      widget.bridge.openAccessibilitySettings(),
                                  icon: const Icon(
                                    Icons.accessibility_new,
                                    size: 18,
                                  ),
                                  label: Text(
                                    context.tr('setup_wizard_step2_btn'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Алхам 3: Battery Optimization ("Unrestricted")
                        PermissionStepCard(
                          stepNumber: 3,
                          title: context.tr('setup_wizard_step3_title'),
                          description: context.tr('setup_wizard_step3_desc'),
                          isCompleted: _status.batteryIgnored,
                          child: _status.batteryIgnored
                              ? const SizedBox.shrink()
                              : OutlinedButton.icon(
                                  onPressed: () => widget.bridge
                                      .requestIgnoreBatteryOptimizations(),
                                  icon: const Icon(
                                    Icons.battery_charging_full,
                                    size: 18,
                                  ),
                                  label: Text(
                                    context.tr('setup_wizard_step3_btn'),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (ctx) => const HomeScreen(),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: _status.isAllGranted
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.primary,
                            ),
                            child: Text(
                              _status.isAllGranted
                                  ? context.tr('setup_wizard_done_btn')
                                  : context.tr('setup_wizard_continue_btn'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
