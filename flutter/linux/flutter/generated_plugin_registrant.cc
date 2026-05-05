//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_linux/audioplayers_linux_plugin.h>
#include <desktop_window/desktop_window_plugin.h>
#include <flutter_core/flutter_core_plugin.h>
#include <flutter_localization/flutter_localization_plugin.h>
#include <flutter_ui_base/flutter_ui_base_plugin.h>
#include <my_graphs/my_graphs_plugin.h>
#include <my_localizations/my_localizations_plugin.h>
#include <my_logger_metrics/my_logger_metrics_plugin.h>
#include <my_theme_style/my_theme_style_plugin.h>
#include <url_launcher_linux/url_launcher_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) audioplayers_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AudioplayersLinuxPlugin");
  audioplayers_linux_plugin_register_with_registrar(audioplayers_linux_registrar);
  g_autoptr(FlPluginRegistrar) desktop_window_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "DesktopWindowPlugin");
  desktop_window_plugin_register_with_registrar(desktop_window_registrar);
  g_autoptr(FlPluginRegistrar) flutter_core_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterCorePlugin");
  flutter_core_plugin_register_with_registrar(flutter_core_registrar);
  g_autoptr(FlPluginRegistrar) flutter_localization_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterLocalizationPlugin");
  flutter_localization_plugin_register_with_registrar(flutter_localization_registrar);
  g_autoptr(FlPluginRegistrar) flutter_ui_base_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterUiBasePlugin");
  flutter_ui_base_plugin_register_with_registrar(flutter_ui_base_registrar);
  g_autoptr(FlPluginRegistrar) my_graphs_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MyGraphsPlugin");
  my_graphs_plugin_register_with_registrar(my_graphs_registrar);
  g_autoptr(FlPluginRegistrar) my_localizations_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MyLocalizationsPlugin");
  my_localizations_plugin_register_with_registrar(my_localizations_registrar);
  g_autoptr(FlPluginRegistrar) my_logger_metrics_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MyLoggerMetricsPlugin");
  my_logger_metrics_plugin_register_with_registrar(my_logger_metrics_registrar);
  g_autoptr(FlPluginRegistrar) my_theme_style_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MyThemeStylePlugin");
  my_theme_style_plugin_register_with_registrar(my_theme_style_registrar);
  g_autoptr(FlPluginRegistrar) url_launcher_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "UrlLauncherPlugin");
  url_launcher_plugin_register_with_registrar(url_launcher_linux_registrar);
}
