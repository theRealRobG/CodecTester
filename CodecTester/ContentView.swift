import AVFoundation
import SwiftUI

struct ContentView: View {
    let testRunner = CodecTestRunner()

    @State var fallbackCodecs = "avc1.4d4015"
    @State var preferredCodecs = ""
    @State var result: Result<CodecSupportDecision, Error>?

    var body: some View {
        VStack {
            PlayerView(player: testRunner.player)
                .ignoresSafeArea(.all, edges: .all)
                .background { Color.black }

            if let result {
                VStack {
                    HStack {
                        Text("Result:")
                            .font(.headline)
                            .padding(.horizontal)

                        Spacer()

                        Text(stringify(result: result))

                        Spacer()
                    }
                }
                .padding(.all, 5)
            }

            Spacer()

            InputCodecsView(fallbackCodecs: $fallbackCodecs, preferredCodecs: $preferredCodecs)

            Button("Test") {
                result = nil
                testRunner.run(fallbackCodecs: fallbackCodecs, preferredCodecs: preferredCodecs) { result = $0 }
            }
            .padding()

            Spacer()
        }
    }

    private func stringify(result: Result<CodecSupportDecision, Error>) -> String {
        switch result {
        case .success(let success):
            switch success {
            case .fallback:
                return "Fallback chosen."
            case .preferred:
                return "Preferred chosen."
            }
        case .failure(let failure):
            return "Player failed with error: \(failure)"
        }
    }
}

#Preview {
    ContentView(result: .success(.preferred))
}
