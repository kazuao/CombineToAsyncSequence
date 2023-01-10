//
//  ContentView2.swift
//  CombineToAsyncSequence
//
//  Created by kazunori.aoki on 2023/01/06.
//

import SwiftUI
import Combine

struct ContentView2: View {

    @StateObject var viewModel = ConcurrencyViewModel()

    var body: some View {
        VStack {
            Text(viewModel.numberText)
                .font(.largeTitle)
                .padding(20)
            HStack {
                Button {
                    viewModel.startTimer()
                } label: {
                    Image(systemName: "play.circle.fill")
                        .imageScale(.medium)
                }
                Button {
                    viewModel.stopTimer()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .imageScale(.medium)
                }
            }
        }
        .padding()
    }
}

// MARK: - Combine
final class CombineViewModel: ObservableObject {
    @Published var numberText: String

    private let model = CombineModel()
    private var cancellable: AnyCancellable?

    init() {
        numberText = String(Int.random(in: 1..<10))
        cancellable = model.publisher
            .sink { [weak self] value in
                self?.numberText = String(value)
            }
    }

    deinit { cancellable?.cancel() }

    func startTimer() {
        model.startTimer()
    }

    func stopTimer() {
        model.stopTimer()
    }
}

final class CombineModel {
    private var cancellable: AnyCancellable?
    private let subject = PassthroughSubject<Int, Never>()

    var publisher: AnyPublisher<Int, Never> {
        return subject.eraseToAnyPublisher()
    }

    init() {}

    deinit { cancellable?.cancel() }

    func startTimer() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.subject.send(Int.random(in: 1..<10))
            }
    }

    func stopTimer() {
        cancellable?.cancel()
    }
}


// MARK: - Swift Concurrency
final class ConcurrencyViewModel: ObservableObject {
    @Published var numberText: String

    private let model = ConcurrencyModel()
    private let model2 = ConcurrencyModel()

    private var task: Task<Void, Never>?
    private var task2: Task<Void, Never>?

    init() {
        numberText = String(Int.random(in: 1..<10))

        task = Task {
            for await value in model.randomNumber {
                Task.detached { @MainActor [weak self] in
                    self?.numberText = String(value)
                }
            }
        }

        task2 = Task {
            for await value in model2.randomNumber {
                print(value)
            }
        }
    }

    deinit { task?.cancel() }

    func startTimer() {
        model.startTimer()
    }

    func stopTimer() {
        model.stopTimer()
    }
}

final class ConcurrencyModel {
    private var timer: Timer?
    private var handler: ((Int) -> Void)?
    var randomNumber: AsyncStream<Int> {
        return AsyncStream { continuation in
            self.handler = { value in
                continuation.yield(value)
            }
        }
    }

    init() {}

    deinit { timer?.invalidate() }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            self?.handler?(Int.random(in: 0..<10))
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}



struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}
