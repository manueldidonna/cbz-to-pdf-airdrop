import AppKit
import ArgumentParser
import Foundation
import PDFKit
import ZIPFoundation

@main
struct ComicBookZipToPdf: ParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "cbz-to-pdf")

    @Argument(
        help: "Comic archives to convert. Allowed formats: .cbz",
        completion: .file(extensions: ["cbz"]),
        transform: { URL(fileURLWithPath: $0) }
    )
    var files: [URL] = []

    @Flag(help: "Share converted files over AirDrop.")
    var airdrop: Bool = false

    @Flag(help: "Shows information that does not interest everyone")
    var verbosePrints: Bool = false

    @Option(
        help: "Directory in which to save the converted files.",
        completion: .directory,
        transform: { path in URL(fileURLWithPath: path) }
    )
    var outputDirectory: URL? = nil

    func validate() throws {
        if files.isEmpty {
            throw ValidationError("You have to pass at least one file to convert.")
        }

        if files.contains(where: { url in url.isDirectory == true }) {
            throw ValidationError("You can't convert a directory. Specify the files paths.")
        }

        if files.contains(where: { url in url.pathExtension != "cbz" }) {
            throw ValidationError("The tool accepts .cbz archives only.")
        }

        let fileManager = FileManager.default
        if files.contains(where: { url in !fileManager.fileExists(atPath: url.path) }) {
            throw ValidationError("At least one file you passed doesn't exists.")
        }

        if files.contains(where: { url in url.isReadable == false }) {
            throw ValidationError("No read access to files")
        }

        if !airdrop, outputDirectory == nil {
            throw ValidationError("You have to enable AirDrop sharing or specify an output directory.")
        }

        if outputDirectory != nil, outputDirectory?.isDirectory == false {
            throw ValidationError("The directory you passed isn't a valid output destination.")
        }
    }

    mutating func run() throws {
        print("👋 You passed \(files.count) comic(s) to convert!")
        files.forEach { url in print("- \(booksEmoji.randomElement() ?? "") \(url.deletingPathExtension().lastPathComponent)") }

        if !askConfirmationToProceed() {
            ComicBookZipToPdf.exit(withError: ExitCode.success)
        }

        do {
            print("\n🚧👷 Starting conversion...")
            let convertedFiles = files
                .map { file in convertArchiveToPdf(archive: file, outputDirectory: outputDirectory) }
                .filter { url in url != nil }

            if convertedFiles.isEmpty {
                print("😔 None of your files passed the conversion.")
                return
            }

            if outputDirectory != nil {
                print("🔎 You can find your converted files in: \(outputDirectory?.relativePath ?? "")")
            }

            if airdrop {
                print("\n🚀 Sending \(convertedFiles.count) comic(s) over AirDrop...")

                // Can't capture struct property in an escaping closure
                let verbose = verbosePrints

                let task = AirDropTask(
                    onExecutionEnd: {
                        print("✅ Files were sent successfully!")
                        if verbose {
                            print("🧹 Some temporary files will be removed by the OS in the next few days.")
                        }
                        ComicBookZipToPdf.exit(withError: ExitCode.success)
                    },
                    itemsToSend: convertedFiles as [Any]
                )
                try task.execute()

                // Wait until AirDropTask ends
                RunLoop.main.run()
            }
        } catch {
            print("⚠️ Error: \(error)")
        }
    }

    private func askConfirmationToProceed() -> Bool {
        print("\n🤔 Are you sure you want to proceed? [y/n] ", terminator: "")
        var agree: Bool?
        repeat {
            switch readLine()?.lowercased() {
            case "y", "yes":
                agree = true
            case "n", "no":
                agree = false
            default:
                print("Invalid input. Type [y/n]: ", terminator: "")
            }
        } while agree == nil
        return agree ?? false
    }

    private struct ArchiveMissingImageError: Error {}
    private struct EmptyExtractedArchiveError: Error {}

    private func convertArchiveToPdf(archive: URL, outputDirectory: URL? = nil) -> URL? {
        let sourceName = archive.deletingPathExtension().lastPathComponent
        do {
            let fileManager = FileManager.default

            guard let unzippedArchiveDirectory = unzipComicsArchive(archive) else {
                return nil
            }

            let comicImages = try fileManager.contentsOfDirectory(atPath: unzippedArchiveDirectory.path).sorted()
            if comicImages.isEmpty {
                throw EmptyExtractedArchiveError()
            }

            let document = PDFDocument()
            for index in 0 ..< comicImages.count {
                let imageUrl = unzippedArchiveDirectory.appendingPathComponent(comicImages[index])
                guard let image = NSImage(byReferencingFile: imageUrl.path) else {
                    throw ArchiveMissingImageError()
                }
                document.insert(PDFPage(image: image)!, at: index)
            }

            let pdfDirectory = outputDirectory ?? fileManager.temporaryDirectory
            let pdfFile = pdfDirectory.appendingPathComponent("\(sourceName).pdf")

            // Remove the pdf from the destination if it already exists
            try fileManager.removeIfExists(pdfFile)

            // Save converted file
            try document.dataRepresentation()?.write(to: pdfFile)

            // Delete unzipped files after conversion
            try fileManager.removeItem(at: unzippedArchiveDirectory)

            print("💾 \(sourceName) converted!")
            return pdfFile
        } catch {
            print("⚠️ PDF conversion of (\(sourceName)) failed with error: \(error)")
            return nil
        }
    }

    private func unzipComicsArchive(_ file: URL) -> URL? {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let archiveName = file.deletingPathExtension().lastPathComponent
        let archiveDest = tempDirectory.appendingPathComponent(archiveName)
        do {
            try fileManager.removeIfExists(archiveDest)
            try fileManager.unzipItem(at: file, to: archiveDest)
            return archiveDest
        } catch {
            print("⚠️ Extraction of (\(archiveName)) failed with error: \(error)")
            return nil
        }
    }
}

private let booksEmoji = ["📗", "📘", "📙", "📕"]

private extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var isReadable: Bool {
        (try? resourceValues(forKeys: [.isReadableKey]))?.isReadable == true
    }
}

private extension FileManager {
    func removeIfExists(_ file: URL) throws {
        if fileExists(atPath: file.path) {
            try removeItem(at: file)
        }
    }
}
