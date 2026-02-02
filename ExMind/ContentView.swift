//
//  ContentView.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MindMapDocument.modifiedAt, order: .reverse) private var documents: [MindMapDocument]
    @State private var selectedDocument: MindMapDocument?
    
    var body: some View {
        NavigationSplitView {
            DocumentListView(documents: documents, selectedDocument: $selectedDocument)
                .toolbar {
                    ToolbarItem {
                        Button(action: addDocument) {
                            Label("New Mind Map", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            if let document = selectedDocument {
                MindMapEditorView(document: document)
            } else {
                Text("Select a mind map or create a new one")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func addDocument() {
        withAnimation {
            let newDocument = MindMapDocument(title: "New Mind Map")
            modelContext.insert(newDocument)
            selectedDocument = newDocument
        }
    }
}

// 문서 목록 뷰
struct DocumentListView: View {
    let documents: [MindMapDocument]
    @Binding var selectedDocument: MindMapDocument?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List(selection: $selectedDocument) {
            ForEach(documents) { document in
                NavigationLink(value: document) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.title)
                            .font(.headline)
                        Text(document.modifiedAt, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteDocument(document)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("ExMind")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250)
#endif
    }
    
    private func deleteDocument(_ document: MindMapDocument) {
        withAnimation {
            modelContext.delete(document)
            if selectedDocument?.id == document.id {
                selectedDocument = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MindMapDocument.self, inMemory: true)
}
