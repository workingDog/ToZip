//
//  ContentView.swift
//  ToZip
//
//  Created by Ringo Wathelet on 2026/02/22.
//
import SwiftUI
import UniformTypeIdentifiers
import ZipArchive


struct ContentView: View {
    var body: some View {
#if os(iOS)
        ContentViewIOS()
#else
        ContentViewMAC()
#endif
        
    }
}

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
        VStack(spacing: 20) {
            
            // Header
            ZStack {
                Text("Encrypt and ZIP").font(.title)
                
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill").font(.title)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding([.horizontal, .top])

            // File info
            Label(fileURL.lastPathComponent, systemImage: "doc.fill")
                .font(.title2)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal)
            
            Divider()
            
            VStack(spacing: 12) {
                PasswordTextField(title: "ZIP File Password", text: $thePassword)
                PasswordTextField(title: "Confirm Password", text: $retryPassword)
                                
                Text(thePassword.trimmingCharacters(in: .whitespaces).isEmpty ? " " : "Password strength: \(pswStrength.strength.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
       
                if !errorMsg.isEmpty {
                    Text(errorMsg)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save ZIP") {
                    if passwordsMatch {
                        createEncryptedZipData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!passwordsMatch || fileData.isEmpty)
            }
            .padding(.bottom)
        }
        .frame(minWidth: 360, minHeight: 280)
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






// under construction
struct ContentViewIOS: View {
    
    @State private var fileData = Data()
    @State private var errorMsg = ""
    @State private var fileURL: URL = FileManager.default.temporaryDirectory
    @State private var showTextImporter = false
    
    var body: some View {
        VStack(spacing: 35) {
            
            Button("Input text file"){
                fileData = Data()
                errorMsg = ""
                showTextImporter = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(!fileData.isEmpty)
            .padding(.top, 50)
            
            if !fileData.isEmpty {
                Text(fileURL.lastPathComponent).font(.title)
                FileZipExporterViewIOS(fileData: $fileData, fileURL: $fileURL, errorMsg: $errorMsg)
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

struct FileZipExporterViewIOS: View {
    
    @Binding var fileData: Data
    @Binding var fileURL: URL
    @Binding var errorMsg: String
    
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
                Button("Save to ZIP file") {
                    if passwordsMatch {
                        createEncryptedZipData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!passwordsMatch || fileData.isEmpty)
                .padding(.horizontal, 20)
                
                Button("Clear Passwords") {
                    thePassword = ""
                    retryPassword = ""
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
                exportData.resetBytes(in: 0..<exportData.count)
                exportData = Data()
                thePassword = ""
                retryPassword = ""
                fileData = Data()
            case .failure(let error):
                print(error)
                exportData = Data()
                thePassword = ""
                retryPassword = ""
                errorMsg = "Could not export the file. Please try again."
            }
        }
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
