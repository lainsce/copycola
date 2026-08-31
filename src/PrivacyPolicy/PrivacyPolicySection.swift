import SwiftUI

struct PrivacyPolicySection: View {
    let title: LocalizedStringResource
    let systemImage: String
    let text: LocalizedStringResource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(CopycolaTypography.contentBlockTitle)
            Text(text)
                .font(CopycolaTypography.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
