//
//  ContentViewMAC.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import SwiftUI
import UniformTypeIdentifiers
import ZipArchive


struct ContentViewMAC: View {
    
    @State private var fileData = Data()
    @State private var errorMsg = ""
    @State private var fileURL: URL = FileManager.default.temporaryDirectory
    @State private var showTextImporter = false
    @State private var showPasswordSheet = false
    @State private var isTargeted = false
    
    var body: some View {
        ZStack {
            // Drop zone
            RoundedRectangle(cornerRadius: 20)
                .overlay { Image("zipy").resizable().scaledToFill() }
                .clipShape(Rectangle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(30)
            
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Drop a file here")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("or").font(.title).foregroundColor(.accentColor)
                
                Button("Browse for File") {
                    fileData = Data()
                    errorMsg = ""
                    showTextImporter = true
                }
                .buttonStyle(.borderedProminent)
                .padding(8)
                
                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .overlay {
            Rectangle().fill(Color.accentColor.opacity(isTargeted ? 0.2 : 0))
        }
        .shadow(color: isTargeted ? Color.accentColor.opacity(0.4) : .clear, radius: 12)
        .dropDestination(for: URL.self) { urls, location in
            handleDrop(urls: urls)
        } isTargeted: { hovering in
            isTargeted = hovering
        }
        .fileImporter(
            isPresented: $showTextImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let file = urls.first {
                    fileURL = file
                    readFileContent()
                }
            case .failure(let error):
                errorMsg = error.localizedDescription
            }
        }
        .sheet(isPresented: $showPasswordSheet) {
            FileZipExporterView(
                fileData: $fileData,
                fileURL: $fileURL,
                errorMsg: $errorMsg,
                isPresented: $showPasswordSheet
            )
        }
    }
    
    func handleDrop(urls: [URL]) -> Bool {
        guard let url = urls.first else { return false }
        guard url.isFileURL else { return false }
        fileURL = url
        readDroppedFileContent(url: url)
        return true
    }
    
    func readDroppedFileContent(url: URL) {
        do {
            fileData = try Data(contentsOf: url)
            errorMsg = ""
            showPasswordSheet = true
        } catch {
            errorMsg = error.localizedDescription
        }
    }
    
    func readFileContent() {
        guard fileURL.startAccessingSecurityScopedResource() else { return }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        do {
            fileData = try Data(contentsOf: fileURL)
            errorMsg = ""
            showPasswordSheet = true
        } catch {
            errorMsg = error.localizedDescription
        }
    }
}
