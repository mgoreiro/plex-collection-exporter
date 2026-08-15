import SwiftUI

struct ContentView: View {
    @StateObject private var store = PlexStore()

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
        } content: {
            CollectionListView(store: store)
        } detail: {
            CollectionDetailView(store: store)
        }
        .frame(minWidth: 1000, minHeight: 640)
    }
}
