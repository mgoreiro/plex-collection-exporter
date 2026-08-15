import Foundation

@MainActor
final class PlexStore: ObservableObject {
    @Published var serverURL: String = UserDefaults.standard.string(forKey: "plexServerURL") ?? "http://192.168.1.100:32400"
    @Published var token: String = KeychainHelper.load(key: "plexToken") ?? ""

    @Published var isConnected: Bool = false
    @Published var isConnecting: Bool = false
    @Published var connectionError: String?

    @Published var libraries: [PlexLibrary] = []
    @Published var selectedLibrary: PlexLibrary?

    @Published var collections: [PlexCollection] = []
    @Published var isLoadingCollections: Bool = false
    @Published var selectedCollection: PlexCollection?

    @Published var items: [PlexItem] = []
    @Published var isLoadingItems: Bool = false
    @Published var itemsError: String?

    @Published var lastExportedURL: URL?
    @Published var exportError: String?

    private var client: PlexClient?

    func connect() async {
        connectionError = nil
        isConnecting = true
        defer { isConnecting = false }
        do {
            let newClient = try PlexClient(baseURLString: serverURL, token: token)
            try await newClient.testConnection()
            client = newClient
            isConnected = true
            UserDefaults.standard.set(serverURL, forKey: "plexServerURL")
            KeychainHelper.save(key: "plexToken", value: token)
            await loadLibraries()
        } catch {
            isConnected = false
            client = nil
            connectionError = (error as? PlexClientError)?.errorDescription ?? error.localizedDescription
        }
    }

    func disconnect() {
        client = nil
        isConnected = false
        libraries = []
        collections = []
        items = []
        selectedLibrary = nil
        selectedCollection = nil
    }

    func loadLibraries() async {
        guard let client else { return }
        do {
            libraries = try await client.fetchLibraries().filter { $0.type == "movie" || $0.type == "show" }
        } catch {
            connectionError = (error as? PlexClientError)?.errorDescription ?? error.localizedDescription
        }
    }

    func selectLibrary(_ library: PlexLibrary) async {
        selectedLibrary = library
        selectedCollection = nil
        items = []
        collections = []
        await loadCollections()
    }

    func loadCollections() async {
        guard let client, let library = selectedLibrary else { return }
        isLoadingCollections = true
        defer { isLoadingCollections = false }
        do {
            collections = try await client.fetchCollections(sectionKey: library.key)
        } catch {
            connectionError = (error as? PlexClientError)?.errorDescription ?? error.localizedDescription
            collections = []
        }
    }

    func selectCollection(_ collection: PlexCollection) async {
        selectedCollection = collection
        itemsError = nil
        guard let client else { return }
        isLoadingItems = true
        defer { isLoadingItems = false }
        do {
            items = try await client.fetchCollectionItems(ratingKey: collection.ratingKey)
        } catch {
            itemsError = (error as? PlexClientError)?.errorDescription ?? error.localizedDescription
            items = []
        }
    }

    func exportCurrentCollection() {
        guard let collection = selectedCollection, !items.isEmpty else { return }
        exportError = nil
        CSVExporter.exportWithSavePanel(items: items, suggestedName: collection.title) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let url):
                    self?.lastExportedURL = url
                case .failure(let error):
                    self?.exportError = error.localizedDescription
                }
            }
        }
    }
}
