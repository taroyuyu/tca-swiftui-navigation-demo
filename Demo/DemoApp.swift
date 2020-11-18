import Combine
import ComposableArchitecture
import SwiftUI

@main
struct DemoApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        FirstView(store: Store(
          initialState: FirstState(),
          reducer: firstReducer.debug(),
          environment: AppEnvironment()
        ))
      }
      .navigationViewStyle(StackNavigationViewStyle())
    }
  }
}

struct AppEnvironment {
  var mainScheduler: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler()
}

// MARK: - First

struct FirstState: Equatable {
  var presentSecond = false
  var second: SecondState?
}

enum FirstAction: Equatable {
  case presentSecond(Bool)
  case didDismissSecond
  case second(SecondAction)
}

let firstReducer = Reducer<FirstState, FirstAction, AppEnvironment>.combine(
  secondReducer.optional().pullback(
    state: \.second,
    action: /FirstAction.second,
    environment: { $0 }
  ),
  Reducer { state, action, environment in
    switch action {
    case let .presentSecond(present):
      state.presentSecond = present
      if present {
        state.second = SecondState()
        return .none
      } else {
        return Effect(value: .didDismissSecond)
          .delay(for: .seconds(1), scheduler: environment.mainScheduler)
          .eraseToEffect()
      }

    case .didDismissSecond:
      if state.presentSecond == false {
        state.second = nil
      }
      return .none

    case .second(.third(.dismissToFirst)):
      return .init(value: .presentSecond(false))

    case .second:
      return .none
    }
  }
)

struct FirstViewState: Equatable {
  let presentSecond: Bool

  init(state: FirstState) {
    presentSecond = state.presentSecond
  }
}

struct FirstView: View {
  let store: Store<FirstState, FirstAction>

  var body: some View {
    WithViewStore(store.scope(state: FirstViewState.init(state:))) { viewStore in
      NavigationLink(
        destination: IfLetStore(
          store.scope(
            state: \.second,
            action: FirstAction.second
          ),
          then: SecondView.init(store:)
        ),
        isActive: viewStore.binding(get: \.presentSecond, send: FirstAction.presentSecond),
        label: { Text("Present Second") }
      )
      .navigationTitle("First")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

// MARK: - Second

struct SecondState: Equatable {
  var presentThird = false
  var third: ThirdState?
}

enum SecondAction: Equatable {
  case presentThird(Bool)
  case didDismissThird
  case third(ThirdAction)
}

let secondReducer = Reducer<SecondState, SecondAction, AppEnvironment>.combine(
  thirdReducer.optional().pullback(
    state: \.third,
    action: /SecondAction.third,
    environment: { $0 }
  ),
  Reducer { state, action, environment in
    switch action {
    case let .presentThird(present):
      state.presentThird = present
      if present {
        state.third = ThirdState()
        return .none
      } else {
        return Effect(value: .didDismissThird)
          .delay(for: .seconds(1), scheduler: environment.mainScheduler)
          .eraseToEffect()
      }

    case .didDismissThird:
      if state.presentThird == false {
        state.third = nil
      }
      return .none

    case .third:
      return .none
    }
  }
)

struct SecondViewState: Equatable {
  let presentThird: Bool

  init(state: SecondState) {
    presentThird = state.presentThird
  }
}

struct SecondView: View {
  let store: Store<SecondState, SecondAction>

  var body: some View {
    WithViewStore(store.scope(state: SecondViewState.init(state:))) { viewStore in
      ZStack {
        Color.green.ignoresSafeArea()

        NavigationLink(
          destination: IfLetStore(
            store.scope(
              state: \.third,
              action: SecondAction.third
            ),
            then: ThirdView.init(store:)
          ),
          isActive: viewStore.binding(get: \.presentThird, send: SecondAction.presentThird),
          label: { Text("Present Third") }
        )
      }
      .navigationTitle("Second")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

// MARK: - Third

struct ThirdState: Equatable {}

enum ThirdAction: Equatable {
  case dismissToFirst
}

let thirdReducer = Reducer<ThirdState, ThirdAction, AppEnvironment>.empty

struct ThirdView: View {
  let store: Store<ThirdState, ThirdAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      ZStack {
        Color.yellow.ignoresSafeArea()

        Button(action: { viewStore.send(.dismissToFirst) }) {
          Text("Dismiss to First")
        }
      }
      .navigationTitle("Third")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}
