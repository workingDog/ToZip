//
//  FileZipExporterView.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import SwiftUI
import UniformTypeIdentifiers
import ZipArchive



struct FileZipExporterView: View {

    @Binding var fileData: Data
    @Binding var fileURL: URL
    @Binding var errorMsg: String
    @Binding var isPresented: Bool
    
    @State private var thePassword = ""
    @State private var retryPassword = ""
    @State private var showExporter = false
    @State private var exportData = Data()
    
    var pswStrength: PasswordStrengthResult {
        PasswordStrengthEvaluator.evaluate(thePassword)
    }
    
    var passwordsMatch: Bool {
        !thePassword.trim().isEmpty && thePassword.trim() == retryPassword.trim()
    }
    
    var body: some View {
        VStack {
            
            PasswordTextField(title: "ZIP File Password", text: $thePassword)
            PasswordTextField(title: "Confirm Password", text: $retryPassword)
            
            HStack {
                Spacer()
                Button("Save") {
                    if passwordsMatch {
                        createEncryptedZipData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!passwordsMatch || fileData.isEmpty)
                .padding(.horizontal, 20)
                
                Button("Cancel") {
                    thePassword = ""
                    retryPassword = ""
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 20)
                Spacer()
            }
            
            // just for fun
            if !thePassword.trim().isEmpty {
                Text("Password \(pswStrength.strength.rawValue)").padding(.top, 30)
            }
            
        }
        .padding(15)
        .onAppear {
            thePassword = ""
        }
        .onDisappear {
            fileURL = FileManager.default.temporaryDirectory
        }
        .fileExporter(
            isPresented: $showExporter,
            document: ZIPExportDocument(data: exportData),
            contentType: .zip,
            defaultFilename: "\(fileURL.deletingPathExtension().lastPathComponent).zip"
        ) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                print(error)
                exportData = Data()
                thePassword = ""
                retryPassword = ""
                errorMsg = "Could not export the file. Please try again."
            }
        }
    }
    
    func dismiss() {
        exportData = Data()
        thePassword = ""
        retryPassword = ""
        fileData = Data()
        fileURL = FileManager.default.temporaryDirectory
        errorMsg = ""
        isPresented = false
    }
    
    func createEncryptedZipData() {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        
        let tempFileURL = tempDir.appendingPathComponent(fileURL.lastPathComponent)
        
        let tempZipURL = tempDir
            .appendingPathComponent("\(fileURL.lastPathComponent)_\(UUID().uuidString)")
            .appendingPathExtension("zip")
        
        do {
            defer {
                try? fm.removeItem(at: tempFileURL)
                try? fm.removeItem(at: tempZipURL)
            }
            
            // Write ANY file data (text, image, pdf, etc.)
            try fileData.write(to: tempFileURL, options: [.atomic])
            
            let success = SSZipArchive.createZipFile(
                atPath: tempZipURL.path,
                withFilesAtPaths: [tempFileURL.path],
                withPassword: thePassword
            )
            
            guard success else {
                errorMsg = "Error creating encrypted zip."
                return
            }
            
            exportData = try Data(contentsOf: tempZipURL)
            showExporter = true
            
        } catch {
            errorMsg = error.localizedDescription
        }
    }
    
}

struct PasswordTextField: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        TextField(title, text: $text)
            .autocorrectionDisabled()
            .noAutoCapitalization()
            .textFieldStyle(.plain)
            .foregroundColor(.primary)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary, lineWidth: 1.5)
            )
    }
}

struct ZIPExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }
    
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
