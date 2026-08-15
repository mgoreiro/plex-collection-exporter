import Foundation

// MARK: - Contenedor genérico de respuestas de Plex

struct PlexMediaContainer<T: Codable>: Codable {
    let mediaContainer: MediaContainerContent<T>

    enum CodingKeys: String, CodingKey {
        case mediaContainer = "MediaContainer"
    }
}

struct MediaContainerContent<T: Codable>: Codable {
    let size: Int?
    let directory: [T]?
    let metadata: [T]?

    enum CodingKeys: String, CodingKey {
        case size
        case directory = "Directory"
        case metadata = "Metadata"
    }
}

// MARK: - Librerías (secciones)

struct PlexLibrary: Codable, Identifiable, Hashable {
    let key: String
    let title: String
    let type: String

    var id: String { key }
}

// MARK: - Etiquetas (género, director, actor, guionista...)

struct PlexTag: Codable, Hashable {
    let tag: String
}

// MARK: - Colecciones

struct PlexCollection: Codable, Identifiable, Hashable {
    let ratingKey: String
    let title: String
    let childCount: Int?
    let summary: String?

    var id: String { ratingKey }

    static func == (lhs: PlexCollection, rhs: PlexCollection) -> Bool {
        lhs.ratingKey == rhs.ratingKey
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(ratingKey)
    }
}

// MARK: - Elementos (películas / episodios / series)

struct PlexItem: Codable, Identifiable, Hashable {
    let ratingKey: String
    let title: String
    let type: String?
    let year: Int?
    let rating: Double?
    let contentRating: String?
    let studio: String?
    let summary: String?
    let duration: Int?
    let originallyAvailableAt: String?
    let addedAt: Int?

    let genre: [PlexTag]?
    let director: [PlexTag]?
    let writer: [PlexTag]?
    let role: [PlexTag]?

    var id: String { ratingKey }

    enum CodingKeys: String, CodingKey {
        case ratingKey, title, type, year, rating, contentRating, studio, summary, duration, originallyAvailableAt, addedAt
        case genre = "Genre"
        case director = "Director"
        case writer = "Writer"
        case role = "Role"
    }

    static func == (lhs: PlexItem, rhs: PlexItem) -> Bool { lhs.ratingKey == rhs.ratingKey }
    func hash(into hasher: inout Hasher) { hasher.combine(ratingKey) }

    var genresJoined: String { (genre ?? []).map { $0.tag }.joined(separator: "; ") }
    var directorsJoined: String { (director ?? []).map { $0.tag }.joined(separator: "; ") }
    var writersJoined: String { (writer ?? []).map { $0.tag }.joined(separator: "; ") }
    var actorsJoined: String { (role ?? []).map { $0.tag }.joined(separator: "; ") }

    var durationFormatted: String {
        guard let d = duration else { return "" }
        let minutes = d / 60000
        return "\(minutes) min"
    }

    var addedDateFormatted: String {
        guard let a = addedAt else { return "" }
        let date = Date(timeIntervalSince1970: TimeInterval(a))
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt.string(from: date)
    }
}
