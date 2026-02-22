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
    
    @State private var fileData = Data()
    @State private var errorMsg = ""
    @State private var fileURL: URL = FileManager.default.temporaryDirectory
    @State private var showTextImporter = false
    
    var body: some View {
        VStack(spacing: 35) {
            Image("zipy").resizable()
                .scaledToFit()
                .padding(10)
            
            if fileData.isEmpty {
                Button("Browse for file"){
                    fileData = Data()
                    errorMsg = ""
                    showTextImporter = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(!fileData.isEmpty)
                .controlSize(.large)
                .padding(.top, 50)
            } else {
                Text(fileURL.lastPathComponent).font(.title)
                FileZipExporterView(fileData: $fileData, fileURL: $fileURL, errorMsg: $errorMsg, isPresented: .constant(true))
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
    
    func readFileContent() {
        guard fileURL.startAccessingSecurityScopedResource() else {  return }
        defer { fileURL.stopAccessingSecurityScopedResource() }
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            print(error)
            errorMsg = error.localizedDescription
        }
    }
    
}
