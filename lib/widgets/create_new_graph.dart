part of 'widgets.dart';

Future<void> createNewGraph(BuildContext context) async {
  final nameController = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Neuen Graphen erstellen'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(labelText: 'Name des Graphen', hintText: 'z.B. TestGraph'),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            Navigator.of(context).pop(name);
            context.read<GraphEditorBloc>().add(GraphEditorMewGraphEvent(name));
          },
          child: const Text('Erstellen'),
        ),
      ],
    ),
  );
}
