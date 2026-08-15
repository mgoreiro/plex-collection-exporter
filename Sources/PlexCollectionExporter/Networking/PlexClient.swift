import Foundation

enum PlexClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case http(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL del servidor no válida. Usa algo como http://192.168.1.10:32400"
        case .invalidResponse:
            return "Respuesta no válida del servidor Plex."
        case .http(let code):
            return code == 401
                ? "Token no válido o caducado (401)."
                : "El servidor Plex respondió con el código \(code)."
        case .decoding(let err):
            return "Error al interpretar la respuesta de Plex: \(err.localizedDescription)"
        }
    }
}

final class PlexClient {
    let baseURL: URL
    let token: String

    init(baseURLString: String, token: String) throws {
        var urlString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.hasSuffix("/") { urlString.removeLast() }
        guard let url = URL(string: urlString), url.scheme != nil, url.host != nil else {
            throw PlexClientError.invalidURL
        }
        self.baseURL = url
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func makeRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw PlexClientError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw PlexClientError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Plex-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        return request
    }

    private func fetch<T: Decodable>(path: String, queryItems: [URLQueryItem] = []) async throws -> MediaContainerContent<T> {
        let request = try makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw PlexClientError.invalidResponse }
        guard (200...299).contains(httpResponse.statusCode) else { throw PlexClientError.http(httpResponse.statusCode) }
        do {
            let container = try JSONDecoder().decode(PlexMediaContainer<T>.self, from: data)
            return container.mediaContainer
        } catch {
            throw PlexClientError.decoding(error)
        }
    }

    /// Comprueba que el servidor responde y el token es válido.
    func testConnection() async throws {
        _ = try await fetch(path: "/identity") as MediaContainerContent<PlexLibrary>
    }

    /// Devuelve todas las librerías (secciones) del servidor.
    func fetchLibraries() async throws -> [PlexLibrary] {
        let container: MediaContainerContent<PlexLibrary> = try await fetch(path: "/library/sections")
        return container.directory ?? []
    }

    /// Devuelve las colecciones de una librería concreta.
    func fetchCollections(sectionKey: String) async throws -> [PlexCollection] {
        let container: MediaContainerContent<PlexCollection> = try await fetch(
            path: "/library/sections/\(sectionKey)/collections"
        )
        return container.metadata ?? []
    }

    /// Devuelve los elementos de una colección con metadatos completos
    /// (géneros, reparto, director...), consultando cada ítem en paralelo.
    func fetchCollectionItems(ratingKey: String) async throws -> [PlexItem] {
        let container: MediaContainerContent<PlexItem> = try await fetch(
            path: "/library/collections/\(ratingKey)/children"
        )
        let items = container.metadata ?? []

        return try await withThrowingTaskGroup(of: PlexItem.self) { group in
            for item in items {
                group.addTask {
                    (try? await self.fetchFullItem(ratingKey: item.ratingKey)) ?? item
                }
            }
            var results: [PlexItem] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        }
    }

    private func fetchFullItem(ratingKey: String) async throws -> PlexItem {
        let container: MediaContainerContent<PlexItem> = try await fetch(path: "/library/metadata/\(ratingKey)")
        guard let item = container.metadata?.first else { throw PlexClientError.invalidResponse }
        return item
    }
}
