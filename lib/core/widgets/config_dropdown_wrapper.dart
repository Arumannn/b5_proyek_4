import 'package:flutter/material.dart';

import 'package:b5_proyek_4/core/services/config_controller.dart';
import '../services/sync_manager.dart';
import 'inline_expanding_dropdown_field.dart';

/// Membungkus logika standar untuk mendengarkan perubahan ConfigController
/// dan SyncManager, serta memastikan bahwa value selalu valid (ada di dalam opsi).
class ConfigDropdownWrapper<T> extends StatelessWidget {
  const ConfigDropdownWrapper({
    super.key,
    required this.value,
    required this.optionsBuilder,
    required this.builder,
  });

  final T? value;
  final List<T> Function(ConfigController) optionsBuilder;
  final Widget Function(
    BuildContext context,
    List<T> options,
    T? safeValue,
    bool isSyncing,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SyncManager.instance.isSyncing,
      builder: (context, isSyncing, _) {
        return ListenableBuilder(
          listenable: ConfigController.instance,
          builder: (context, _) {
            final options = optionsBuilder(ConfigController.instance);
            
            // Guard: pastikan nilai saat ini ada di dalam opsi. Jika tidak, fallback ke elemen pertama (atau null).
            T? safeValue = value;
            if (safeValue != null && !options.contains(safeValue)) {
              debugPrint('ConfigDropdownWrapper Guard triggered. value: $value not in options. Falling back.');
              safeValue = options.isNotEmpty ? options.first : null;
            }

            debugPrint('ConfigDropdownWrapper building with ${options.length} options, safeValue: $safeValue, isSyncing: $isSyncing');
            return builder(context, options, safeValue, isSyncing);
          },
        );
      },
    );
  }
}

/// Helper pembungkus DropdownButtonFormField untuk integrasi mudah dengan konfigurasi dinamis.
class ConfigDrivenDropdownField<T> extends StatelessWidget {
  const ConfigDrivenDropdownField({
    super.key,
    required this.value,
    required this.optionsBuilder,
    required this.onChanged,
    required this.labelText,
    this.prefixIcon,
    this.isExpanded = false,
  });

  final T? value;
  final List<T> Function(ConfigController) optionsBuilder;
  final ValueChanged<T?> onChanged;
  final String labelText;
  final Widget? prefixIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return ConfigDropdownWrapper<T>(
      value: value,
      optionsBuilder: optionsBuilder,
      builder: (context, options, safeValue, isSyncing) {
        // Automatically sync the parent's state if the safe value shifted
        // Note: we can't call setState during build, but the dropdown will
        // use safeValue for display and the user's next action will update it properly.
        // It's also possible to notify the parent in a post-frame callback if strict state tracking is needed.
        if (value != safeValue && safeValue != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(safeValue);
          });
        }

        return DropdownButtonFormField<T>(
          value: safeValue,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: prefixIcon,
            suffixText: isSyncing ? 'Syncing...' : null,
            suffixStyle: const TextStyle(fontSize: 10, color: Colors.blue),
          ),
          isExpanded: isExpanded,
          items: options
              .map(
                (opt) => DropdownMenuItem<T>(
                  value: opt,
                  child: Text(opt.toString()),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
        );
      },
    );
  }
}

/// Helper pembungkus InlineExpandingDropdownField untuk layar yang menggunakannya.
class ConfigDrivenInlineDropdownField<T> extends StatelessWidget {
  const ConfigDrivenInlineDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.optionsBuilder,
    required this.onChanged,
    this.placeholder = 'Pilih salah satu',
  });

  final String label;
  final T? value;
  final List<T> Function(ConfigController) optionsBuilder;
  final ValueChanged<T> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return ConfigDropdownWrapper<T>(
      value: value,
      optionsBuilder: optionsBuilder,
      builder: (context, options, safeValue, isSyncing) {
        
        if (value != safeValue && safeValue != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(safeValue);
          });
        }

        // Kita konversi isSyncing menjadi label tambahan pada judul
        final dynamicLabel = isSyncing ? '$label (Syncing...)' : label;

        return InlineExpandingDropdownField(
          label: dynamicLabel,
          value: safeValue?.toString() ?? '',
          options: options.map((e) => e.toString()).toList(),
          placeholder: placeholder,
          onChanged: (strVal) {
            // Kita asumsikan T adalah String atau bisa dicasting balik, 
            // umumnya untuk dropdown config T adalah String.
            onChanged(strVal as T); 
          },
        );
      },
    );
  }
}
