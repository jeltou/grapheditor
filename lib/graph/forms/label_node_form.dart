part of '../graph.dart';

class LabelNodeForm extends StatelessWidget {
  final Map<String, dynamic> data;

  const LabelNodeForm(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: (data['label'] as String?) ?? '');
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(labelText: 'Label', hintText: 'Enter node label', border: OutlineInputBorder()),
      validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Label is required' : null,
      onChanged: (String v) => data['label'] = v,
      onSaved: (String? v) => data['label'] = v?.trim() ?? '',
    );
  }
}
