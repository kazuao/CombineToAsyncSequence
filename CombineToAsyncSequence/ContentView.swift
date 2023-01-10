//
//  ContentView.swift
//  CombineToAsyncSequence
//
//  Created by kazunori.aoki on 2023/01/05.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 12) {
            Button("tap") {
                viewModel.tap()
            }

            Text(viewModel.text)
        }
        .padding()
    }
}

final class ViewModel: ObservableObject {

    @Published var text: String = "not tap"

    let model = Model()

    private var cancellables: Set<AnyCancellable> = .init()

    init() {
        model.subject
            .sink { _ in
                self.text = "did tap"
            }
            .store(in: &cancellables)
    }

    func tap() {
        model.change()
    }
}

final class Model {

    let subject: PassthroughSubject<Void, Never> = .init()

    func change() {
        subject.send(())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
