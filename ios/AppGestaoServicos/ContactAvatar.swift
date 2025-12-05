import SwiftUI

#if canImport(Contacts) && canImport(UIKit)
import Contacts
import UIKit
#endif

#if canImport(ContactsUI) && canImport(UIKit)
import ContactsUI
#endif

struct ContactAvatarView: View {
    let name: String
    let phone: String?
    let size: CGFloat

    @StateObject private var loader: ContactPhotoLoader

    init(name: String, phone: String?, size: CGFloat = 44) {
        self.name = name
        self.phone = phone
        self.size = size
        _loader = StateObject(wrappedValue: ContactPhotoLoader(name: name, phone: phone))
    }

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(AppTheme.fieldBackground)
                Text(initials(for: name))
                    .font(.headline)
                    .foregroundColor(AppTheme.primary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear {
            loader.loadIfNeeded()
        }
    }

    private func initials(for name: String) -> String {
        let parts = name
            .split(separator: " ")
            .prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0) }
        return letters.joined().uppercased()
    }
}

final class ContactPhotoLoader: ObservableObject {
    @Published var image: UIImage?

    private let name: String
    private let phone: String?
    private var hasTried = false

    init(name: String, phone: String?) {
        self.name = name
        self.phone = phone
    }

    func loadIfNeeded() {
#if canImport(Contacts) && canImport(UIKit)
        guard !hasTried, image == nil else { return }
        hasTried = true

        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        let store = CNContactStore()

        let requestAccessAndFetch: () -> Void = {
            let keys: [CNKeyDescriptor] = [CNContactThumbnailImageDataKey as CNKeyDescriptor]
            let predicate: NSPredicate

            if let phone = self.phone, !phone.isEmpty {
                let digits = phone.filter { $0.isNumber || $0 == "+" }
                let number = CNPhoneNumber(stringValue: digits)
                predicate = CNContact.predicateForContacts(matching: number)
            } else {
                predicate = CNContact.predicateForContacts(matchingName: self.name)
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                    if let data = contacts.first?.thumbnailImageData, let uiImage = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.image = uiImage
                        }
                    }
                } catch {
                    // Silently ignore; fallback to initials.
                }
            }
        }

        switch authStatus {
        case .authorized:
            requestAccessAndFetch()
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, _ in
                guard granted else { return }
                requestAccessAndFetch()
            }
        default:
            break
        }
#endif
    }
}

#if canImport(ContactsUI) && canImport(UIKit)
struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: (CNContact) -> Void
    var onCancel: (() -> Void)?

    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPickerView

        init(parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.onSelect(contact)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.onCancel?()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
}
#endif

