import Foundation
import SwiftUI

struct CountryCode: Identifiable, Hashable {
    let id = UUID()
    let flag: String
    let name: String
    let dialCode: String
}

extension CountryCode {
    static let all: [CountryCode] = [
        CountryCode(flag: "🇺🇸", name: NSLocalizedString("United States", comment: ""), dialCode: "+1"),
        CountryCode(flag: "🇪🇺", name: NSLocalizedString("European Union", comment: ""), dialCode: "+32"),
        CountryCode(flag: "🇵🇹", name: NSLocalizedString("Portugal", comment: ""), dialCode: "+351"),
        CountryCode(flag: "🇪🇸", name: NSLocalizedString("Spain", comment: ""), dialCode: "+34"),
        CountryCode(flag: "🇬🇧", name: NSLocalizedString("United Kingdom", comment: ""), dialCode: "+44"),
        CountryCode(flag: "🇫🇷", name: NSLocalizedString("France", comment: ""), dialCode: "+33"),
        CountryCode(flag: "🇩🇪", name: NSLocalizedString("Germany", comment: ""), dialCode: "+49")
    ]

    static let defaultCode: CountryCode = .all[0]
}

struct CountryCodePicker: View {
    @Binding var selection: CountryCode

    var body: some View {
        Menu {
            ForEach(CountryCode.all) { code in
                Button {
                    selection = code
                } label: {
                    Text("\(code.flag) \(code.dialCode)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selection.flag)
                Text(selection.dialCode)
                    .font(.subheadline)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppTheme.fieldBackground)
            .cornerRadius(10)
        }
    }
}
