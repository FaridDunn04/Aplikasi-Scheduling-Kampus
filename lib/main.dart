import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/database/database_helper.dart';
import 'state/app_state_manager.dart';
import 'services/alarm_notification_service.dart';
import 'screens/main_navigation_screen.dart';
import 'core/theme/app_theme.dart';
import 'package:app_links/app_links.dart';
import 'core/utils/share_data_compressor.dart';
import 'screens/share/dialogs/import_modal_dialog.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // 1. Inisialisasi database lokal SQLite
  await DatabaseHelper.instance.database;

  // 2. Inisialisasi Service Alarm & Pengingat
  AlarmNotificationService.instance.init(rootNavigatorKey);

  // 3. Load seluruh data awal ke state
  await AppStateManager.instance.init();

  // 4. Inisialisasi listener deep link
  _initDeepLinkListener();

  runApp(const UniSchedApp());
}

void _initDeepLinkListener() async {
  final appLinks = AppLinks();

  // Menangkap link saat aplikasi sedang berjalan atau dibuka dari background
  appLinks.uriLinkStream.listen(
    (uri) {
      _handleIncomingUri(uri);
    },
    onError: (err) {
      debugPrint('[DeepLink] Error: $err');
    },
  );

  // Menangkap link saat cold-start (aplikasi pertama kali dibuka lewat klik link)
  try {
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleIncomingUri(initialUri);
    }
  } catch (err) {
    debugPrint('[DeepLink] Initial link error: $err');
  }
}

void _handleIncomingUri(Uri uri) {
  if (uri.scheme == 'unisched' && uri.host == 'import') {
    final data = uri.queryParameters['data'];
    if (data != null) {
      final payload = ShareDataCompressor.decompressPayload(data);
      if (payload != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            // Tampilkan dialog konfirmasi simpan jadwal
            showImportPreview(context, payload);
          }
        });
      }
    }
  }
}

class UniSchedApp extends StatelessWidget {
  const UniSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'UniSched',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigationScreen(),
    );
  }
}
