import 'connectivity_widget_data.dart';
import 'plan_widget_data.dart';

/// Bridge to the platform-native home-screen widget (Android App Widget /
/// iOS WidgetKit) — the "glance journey" from docs/PRODUCT_DISCOVERY.md
/// §3: the user checks the widget without opening the app. Connectivity
/// and plan data are pushed independently rather than through one
/// combined update, mirroring DashboardBloc/ConnectivityBloc's own
/// independence.
abstract class NativeWidgetService {
  Future<void> updateConnectivity(ConnectivityWidgetData data);
  Future<void> updatePlan(PlanWidgetData data);
}
