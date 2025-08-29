import 'package:flutter/material.dart';
import 'package:fores/fores.dart';

import '../pages/editor/blocs/graph_editor/graph_editor_bloc.dart';
import '../routes.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  GraphEditorBloc graphEditorBloc = GraphEditorBloc();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => graphEditorBloc)],
      child: MaterialForesApp(routes: routes, designSize: const Size(1920, 1080)),
    );
  }
}
