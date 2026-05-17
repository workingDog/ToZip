//
//  ContentViewIOS.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import SwiftUI
import UniformTypeIdentifiers
import ZipArchive


struct ContentViewIOS: View {
    
    @State private var errorMsg = ""
    @State private var fileURL: URL?
    @State private var showTextImporter = false
    
    var body: some View {
        VStack(spacing: 10) {
            Image("zipy").resizable()
                .scaledToFit()
                .padding(10)
            
            if fileURL == nil {
                Button("Browse for file"){
                    fileURL = nil
                    errorMsg = ""
                    showTextImporter = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(fileURL != nil)
                .controlSize(.large)
                .padding(.top, 40)
            } else {
                FileZipExporterView(fileURL: $fileURL, errorMsg: $errorMsg)
            }
            
            if !errorMsg.isEmpty {
                Text(errorMsg)
            }
            
            Spacer()
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
                showTextImporter = false
                
            case .failure(let error):
                errorMsg = error.localizedDescription
                print(error)
            }
        }
    }
    
    private func readFileContent() {
        guard let fileURL else {
            errorMsg = "Could not access the selected file."
            return
        }
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        errorMsg = ""
    }
    
}
