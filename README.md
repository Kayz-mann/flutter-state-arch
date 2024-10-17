Custom Redux-like State Management for Flutter
Overview
This project implements a custom Redux-like state management system for Flutter applications. It provides a predictable state container, making it easier to manage and update application state in a consistent manner.
Architecture
The architecture is inspired by Redux and consists of the following key components:

Actions: Describe state changes
Reducer: Specifies how the application's state changes in response to actions
Store: Holds the application state
Middleware: Provides a third-party extension point between dispatching an action and the moment it reaches the reducer

Key Components

ReduxAction: Base class for all actions
ReduxState: Base class for all state objects
Store: Manages the application state and notifies listeners of changes
Reducer: Pure function that takes the current state and an action, and returns a new state
Middleware: Functions that can intercept actions before they reach the reducer

Purpose
The main purposes of this custom state management system are:

Centralized State Management: Maintain all application state in a single place, making it easier to understand and debug the application's data flow.
Predictable State Updates: Ensure that all state changes are made through a standardized process of dispatching actions and using reducers.
Separation of Concerns: Clearly separate the UI logic from the state management logic.
Easy Testing: Facilitate unit testing of state changes by testing reducers and middleware in isolation.
Time-Travel Debugging: Enable the possibility of implementing time-travel debugging by recording the sequence of actions and state changes.

Importance
This custom Redux-like architecture offers several benefits:

Scalability: As your application grows, this architecture helps manage complexity by providing a clear structure for state management.
Maintainability: With a well-defined data flow, it's easier to understand how different parts of the application interact, making maintenance and updates simpler.
Reusability: Actions, reducers, and middleware can be reused across different parts of the application or even in different projects.
Predictability: The unidirectional data flow makes it easier to predict how state changes will affect the application.
Developer Experience: Provides a consistent pattern for managing state, which can improve productivity and reduce bugs related to state management.

Usage
To use this state management system in your Flutter application:

Define your actions by extending ReduxAction.
Create your application state by extending ReduxState.
Implement your reducers as pure functions that take the current state and an action, and return a new state.
Create a Store instance with your initial state and root reducer.
Use the Store in your widgets to access the current state and dispatch actions.
