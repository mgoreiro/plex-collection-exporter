import SwiftUI

struct CollectionListView: View {
    @ObservedObject var store: PlexStore

    var body: some View {
        Group {
            if store.selectedLibrary == nil {
                emptyState("Selecciona una librería", "books.vertical")
            } else if store.isLoadingCollections {
                ProgressView("Cargando colecciones…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.collections.isEmpty {
                emptyState("Esta librería no tiene colecciones", "square.stack")
            } else {
                List(store.collections, selection: Binding<PlexCollection?>(
                    get: { store.selectedCollection },
                    set: { newValue in
                        if let collection = newValue {
                            Task { await store.selectCollection(collection) }
                        }
                    }
                )) { collection in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(collection.title).font(.headline)
                        if let count = collection.childCount {
                            Text("\(count) elementos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(collection)
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(store.selectedLibrary?.title ?? "Colecciones")
        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
    }

    @ViewBuilder
    private func emptyState(_ text: String, _ icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.largeTitle).foregroundStyle(.secondary)
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
