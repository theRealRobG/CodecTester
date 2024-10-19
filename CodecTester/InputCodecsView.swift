import SwiftUI

struct InputCodecsView: View {
    @Binding var fallbackCodecs: String
    @Binding var preferredCodecs: String

    var body: some View {
        VStack {
            InputRow(
                text: $fallbackCodecs,
                description: "Provide the fallback codecs string (expects to be supported)"
            )
            .padding(.bottom)
            InputRow(
                text: $preferredCodecs,
                description: "Provide the preferred codecs string (should be chosen if supported)"
            )
        }
        .padding()
    }
}

extension InputCodecsView {
    struct InputRow: View {
        @Binding var text: String
        let description: String

        var body: some View {
            VStack {
                HStack {
                    Text(description).font(.caption)
                    Spacer()
                }
                TextField(text: $text) {
                    Text("Codec string (e.g. mp4a.40.2)")
                }
                .autocorrectionDisabled()
            }
        }
    }
}

#Preview {
    InputCodecsView(
        fallbackCodecs: .constant("avc1.4d4015,mp4a.40.2"),
        preferredCodecs: .constant("")
    )
}
