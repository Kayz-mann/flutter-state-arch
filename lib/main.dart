import 'package:custom_redux/middleware/increment_action_middleware.dart';
import 'package:custom_redux/reducer/counterReducer.dart';
import 'package:flutter/material.dart';
import 'store/store.dart';
import 'action/action.dart';

// State definitions
abstract class ReduxState {}

class CounterState implements ReduxState {
  final int counter;
  CounterState({this.counter = 0});

  CounterState copyWith({int? counter}) {
    return CounterState(counter: counter ?? this.counter);
  }
}

class AppState implements ReduxState {
  final CounterState counterState;
  AppState({required this.counterState});

  AppState copyWith({CounterState? counterState}) {
    return AppState(counterState: counterState ?? this.counterState);
  }
}

void main() {
  final store = Store<AppState>(
    initialState: AppState(counterState: CounterState()),
    reducer: appReducer,
    middlewares: [incrementMiddleware()],
  );

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Custom Flutter Redux State..', store: store),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  final Store<AppState> store;
  const MyHomePage({super.key, required this.title, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '${store.state.counterState.counter}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Increment'),
                  onPressed: () => store.dispatch(IncrementAction()),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Decrement'),
                  onPressed: () => store.dispatch(DecrementAction()),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Add 100'),
                  onPressed: () => store.dispatch(AddAction(100)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Increment Async'),
                  onPressed: () => store.dispatch(IncrementActionAsync()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
