import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

/// Flutter code sample for [ToggleButtons].

const List<Widget> userType = <Widget>[Text('Client'), Text('Company')];

void main() => runApp(const ToggleButtonsExampleApp());

class ToggleButtonsExampleApp extends StatelessWidget {
  const ToggleButtonsExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ToggleButtonsSample(title: 'ToggleButtons Sample'));
  }
}

class ToggleButtonsSample extends StatefulWidget {
  const ToggleButtonsSample({super.key, required this.title});

  final String title;

  @override
  State<ToggleButtonsSample> createState() => _ToggleButtonsSampleState();
}

class _ToggleButtonsSampleState extends State<ToggleButtonsSample> {
  final List<bool> _selectedUserType = <bool>[true, false];
  bool vertical = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // ToggleButtons with a single selection.
              Text('Single-select', style: theme.textTheme.titleSmall),
              const SizedBox(height: 5),
              ToggleButtons(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                onPressed: (int index) {
                  setState(() {
                    // The button that is tapped is set to true, and the others to false.
                    for (int i = 0; i < _selectedUserType.length; i++) {
                      _selectedUserType[i] = i == index;
                    }
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: AppColors.primary,
                selectedColor: AppColors.primary,
                fillColor: AppColors.accent,
                color: AppColors.textSecondary,
                constraints: const BoxConstraints(minHeight: 40.0, minWidth: 80.0),
                isSelected: _selectedUserType,
                children: userType,
              ),
              const SizedBox(height: 20),
              // ToggleButtons with a multiple selection.
              Text('Multi-select', style: theme.textTheme.titleSmall),
              const SizedBox(height: 5),
              ToggleButtons(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                onPressed: (int index) {
                  // All buttons are selectable.
                  setState(() {
                    _selectedUserType[index] = !_selectedUserType[index];
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: AppColors.primary,
                selectedColor: AppColors.primary,
                fillColor: AppColors.accent,
                color: AppColors.textSecondary,
                constraints: const BoxConstraints(minHeight: 40.0, minWidth: 80.0),
                isSelected: _selectedUserType,
                children: userType,
              ),
              const SizedBox(height: 20),
              // ToggleButtons with icons only.
              Text('Icon-only', style: theme.textTheme.titleSmall),
              const SizedBox(height: 5),
              ToggleButtons(
                direction: vertical ? Axis.vertical : Axis.horizontal,
                onPressed: (int index) {
                  setState(() {
                    // The button that is tapped is set to true, and the others to false.
                    for (int i = 0; i < _selectedUserType.length; i++) {
                      _selectedUserType[i] = i == index;
                    }
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                selectedBorderColor: AppColors.primary,
                selectedColor: AppColors.primary,
                fillColor: AppColors.accent,
                color: AppColors.textSecondary,
                isSelected: _selectedUserType,
                children: userType,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            // When the button is pressed, ToggleButtons direction is changed.
            vertical = !vertical;
          });
        },
        icon: const Icon(Icons.screen_rotation_outlined),
        label: Text(vertical ? 'Horizontal' : 'Vertical'),
      ),
    );
  }
}
