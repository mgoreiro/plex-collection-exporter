import Foundation
import AppKit
import UniformTypeIdentifiers

enum CSVExporter {
    static func csvString(for items: [PlexItem]) -> String {
        let headers = [
            "Título", "Año", "Tipo", "Valoración", "Clasificación", "Estudio",
            "Duración", "Fecha de estreno", "Añadido el",
            "Géneros", "Directores", "Guionistas", "Reparto", "Sinopsis"
        ]
        var lines = [headers.map(escape).joined(separator: ",")]

        for item in items {
            let fields: [String] = [
                item.title,
                item.year.map(String.init) ?? "",
                item.type ?? "",
                item.rating.map { String(format: "%.1f", $0) } ?? "",
                item.contentRating ?? "",
                item.studio ?? "",
                item.durationFormatted,
                item.originallyAvailableAt ?? "",
                item.addedDateFormatted,
                item.genresJoined,
                item.directorsJoined,
                item.writersJoined,
                item.actorsJoined,
                item.summary ?? ""
            ]
            lines.append(fields.map(escape).joined(separator: ","))
        }
        return lines.joined(separator: "\r\n")
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Muestra el panel de guardado nativo de macOS y escribe el CSV en la ruta elegida.
    @MainActor
    static func exportWithSavePanel(items: [PlexItem], suggestedName: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(sanitizeFileName(suggestedName)).csv"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let csv = csvString(for: items)
                try csv.data(using: .utf8)?.write(to: url)
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func sanitizeFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\")
        return name.components(separatedBy: invalid).joined(separator: "-")
    }
}
