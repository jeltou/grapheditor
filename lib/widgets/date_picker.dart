part of 'widgets.dart';

class DateField extends StatefulWidget {
  final DateTime? initial;
  final String label;
  final ValueChanged<DateTime?> onChanged;

  const DateField({required this.initial, required this.label, required this.onChanged});

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial != null
          ? '${widget.initial!.year.toString().padLeft(4, '0')}-'
                '${widget.initial!.month.toString().padLeft(2, '0')}-'
                '${widget.initial!.day.toString().padLeft(2, '0')}'
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _ctrl.text = widget.initial != null
          ? '${widget.initial!.year.toString().padLeft(4, '0')}-'
                '${widget.initial!.month.toString().padLeft(2, '0')}-'
                '${widget.initial!.day.toString().padLeft(2, '0')}'
          : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.event),
          onPressed: () async {
            final now = DateTime.now();
            final initialDate = widget.initial ?? now;
            final picked = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1970), lastDate: DateTime(2100));
            if (picked != null) {
              setState(() {
                _ctrl.text =
                    '${picked.year.toString().padLeft(4, '0')}-'
                    '${picked.month.toString().padLeft(2, '0')}-'
                    '${picked.day.toString().padLeft(2, '0')}';
              });
              widget.onChanged(picked);
            }
          },
        ),
      ),
      onTap: () async {

        final now = DateTime.now();
        final initialDate = widget.initial ?? now;
        final picked = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(1970), lastDate: DateTime(2100));
        if (picked != null) {
          setState(() {
            _ctrl.text =
                '${picked.year.toString().padLeft(4, '0')}-'
                '${picked.month.toString().padLeft(2, '0')}-'
                '${picked.day.toString().padLeft(2, '0')}';
          });
          widget.onChanged(picked);
        }
      },
    );
  }
}
