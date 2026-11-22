import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'app_snackbar.dart';

// Pen icon is only shown when [onSave] true
// [onSave] returns null on success, or an error message

class ProfileFieldTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Future<String?> Function(String value)? onSave;
  final TextInputType keyboardType;
  final String? hint;

  const ProfileFieldTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onSave,
    this.keyboardType = TextInputType.text,
    this.hint,
  });

  @override
  State<ProfileFieldTile> createState() => _ProfileFieldTileState();
}

class _ProfileFieldTileState extends State<ProfileFieldTile> {
  final TextEditingController _controller = TextEditingController();

  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = widget.value.trim();
    setState(() => _editing = true);
  }

  void _cancel() {
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    final error = await widget.onSave!(_controller.text);

    if (!mounted) return;

    setState(() => _saving = false);

    if (error != null) {
      showMessage(context, error);
      return;
    }

    setState(() => _editing = false);
    showMessage(context, 'Profile updated.');
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.value.trim().isEmpty ? 'Not set' : widget.value.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        // center = the icon on the right sits across both lines
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, size: 16, color: kSlate),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: _editing
                      ? TextField(
                          controller: _controller,
                          autofocus: true,
                          enabled: !_saving,
                          keyboardType: widget.keyboardType,
                          onSubmitted: (_) => _save(),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.hint,
                            border: const OutlineInputBorder(),
                          ),
                        )
                      : Text(shown),
                ),
              ],
            ),
          ),

          if (widget.onSave != null) ...[
            const SizedBox(width: 4),
            if (!_editing)
              IconButton(
                tooltip: 'Edit ${widget.label}',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: _startEdit,  // To edit contact info only
              )
            else ...[
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Save',
                      icon: const Icon(Icons.check, size: 20),
                      onPressed: _save,
                    ),
              IconButton(
                tooltip: 'Cancel',
                icon: const Icon(Icons.close, size: 20),
                onPressed: _saving ? null : _cancel,
              ),
            ],
          ],
        ],
      ),
    );
  }
}
