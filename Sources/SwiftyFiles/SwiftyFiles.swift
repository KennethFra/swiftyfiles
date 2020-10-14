import Foundation

enum AppDirectory : String
{
    case mPDFDocuments = "Library/Documents"
    case documents = "Documents"
    case inbox = "Inbox"
    case library = "Library"
    case temp = "tmp"

    var url: URL {
        switch self {
        case .mPDFDocuments:
            return mPDFDocuments
        case .documents:
            return documents
        case .inbox:
            return inbox
        case .library:
            return library
        case .temp:
            return temp
        }
    }

    var mPDFDocuments: URL {
        library.appendingPathComponent("Documents")
    }

    var documents: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    var inbox: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(AppDirectory.inbox.rawValue)
    }

    var library: URL {
        FileManager.default.urls(for: FileManager.SearchPathDirectory.libraryDirectory, in: .userDomainMask).first!
    }

    var temp: URL {
        FileManager.default.temporaryDirectory
    }
}

extension URL {
    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: path)
    }

    var isReadable: Bool {
        FileManager.default.isReadableFile(atPath: path)
    }

    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func attributes() throws -> [FileAttributeKey : Any] {
        try FileManager.default.attributesOfItem(atPath: path)
    }

    var size: Int {
        do {
            let attributes = try resourceValues(forKeys: Set([.fileSizeKey]))
            return attributes.fileSize ?? 0
        } catch {
            return 0
        }
    }

    var modificationDate: Date {
        do {
            let attributes = try resourceValues(forKeys: Set([.attributeModificationDateKey]))
            return attributes.attributeModificationDate ?? Date()
        } catch {
            return Date()
        }
    }

    var isFolder: Bool {
        do {
            let attributes = try resourceValues(forKeys: Set([.isDirectoryKey]))
            return attributes.isDirectory ?? false
        } catch {
            return false
        }
    }
}


protocol FileActions
{
    func create()

    func write(data: Data, to path: AppDirectory, withName name: String) -> Bool

    func read(at path: AppDirectory, withName name: String) -> Data

    func delete(at path: AppDirectory, withName name: String) -> Bool

    func rename(at path: AppDirectory, with oldName: String, to newName: String) -> Bool

    func move(withName name: String, inDirectory: AppDirectory, toDirectory directory: AppDirectory) -> Bool

    func copy(withName name: String, inDirectory: AppDirectory, toDirectory directory: AppDirectory) -> Bool
}

//extension AppFileManipulation
//{
//    func write(data: Data, to path: AppDirectory, withName name: String) -> Bool
//    {
//        let filePath = path.url.appendingPathComponent(name)
//
//        let rawData: Data? = containing.data(using: .utf8)
//        return FileManager.default.createFile(atPath: filePath, contents: rawData, attributes: nil)
//    }
//
//    func readFile(at path: AppDirectories, withName name: String) -> String
//    {
//        let filePath = getURL(for: path).path + "/" + name
//        let fileContents = FileManager.default.contents(atPath: filePath)
//        let fileContentsAsString = String(bytes: fileContents!, encoding: .utf8)
//        print(fileContentsAsString!)
//        return fileContentsAsString!
//    }
//
//    func deleteFile(at path: AppDirectories, withName name: String) -> Bool
//    {
//        let filePath = buildFullPath(forFileName: name, inDirectory: path)
//        try! FileManager.default.removeItem(at: filePath)
//        return true
//    }
//
//    func renameFile(at path: AppDirectories, with oldName: String, to newName: String) -> Bool
//    {
//        let oldPath = getURL(for: path).appendingPathComponent(oldName)
//        let newPath = getURL(for: path).appendingPathComponent(newName)
//        try! FileManager.default.moveItem(at: oldPath, to: newPath)
//
//        // highlights the limitations of using return values
//        return true
//    }
//
//    func moveFile(withName name: String, inDirectory: AppDirectories, toDirectory directory: AppDirectories) -> Bool
//    {
//        let originURL = buildFullPath(forFileName: name, inDirectory: inDirectory)
//        let destinationURL = buildFullPath(forFileName: name, inDirectory: directory)
//        // warning: constant 'success' inferred to have type '()', which may be unexpected
//        // let success =
//        try! FileManager.default.moveItem(at: originURL, to: destinationURL)
//        return true
//    }
//
//    func copyFile(withName name: String, inDirectory: AppDirectories, toDirectory directory: AppDirectories) -> Bool
//    {
//        let originURL = buildFullPath(forFileName: name, inDirectory: inDirectory)
//        let destinationURL = buildFullPath(forFileName: name+"1", inDirectory: directory)
//        try! FileManager.default.copyItem(at: originURL, to: destinationURL)
//        return true
//    }
//
//    func read(_ bytes: Int, startingAt offset: Int = 0, from file: String, at directory: AppDirectories) throws -> String? // STEP 0
//    {
//        var daa: String? = nil
//        var fileHandle: FileHandle
//        // STEP 1
//        var url: URL = buildFullPath(forFileName: file, inDirectory: directory)
//
//        do
//        {
//        }
//        catch // STEP 8
//        {
//            throw FileSystemError(type: .Read, verboseDescription: "Error during read file.", inMethodName: #function, inFileName: #file, atLineNumber: #line)
//        }
//
//        return textRead
//
//    } // end func readBytes
//
//} // end extension AppFileManipulation

class mPDFFile {
    let root: AppDirectory
    let parentPath: String
    let filename: String

    init(root: AppDirectory, parentPath: String, filename: String = "") {
        self.root = root
        self.parentPath = parentPath
        self.filename = filename
    }

    var url: URL {
        return URL(fileURLWithPath: parentPath, relativeTo: root.url).appendingPathComponent(filename)
    }

    func createParentFolder() throws {
        let url = root.url.appendingPathComponent(parentPath)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}

class mPDFDirectory: mPDFFile {
    lazy var urls: [URL]? = {
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        let keys: [URLResourceKey] = [
            .nameKey,
            .isDirectoryKey,
            .contentModificationDateKey,
            .creationDateKey,
            .effectiveIconKey,
            .documentIdentifierKey,
            .fileSizeKey
        ]

        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: keys, options: options, errorHandler: nil) {
            return enumerator.allObjects as? [URL]
        } else {
            return nil
        }
    }()

    init(root: AppDirectory, parentPath: String = "") {
        super.init(root: root, parentPath: parentPath)
    }

    func create() throws {
        let url = root.url.appendingPathComponent(parentPath)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    func search(filter: ((URL)->Bool)) -> [URL] {
        guard let urls = urls else { return [] }
        return urls.filter(filter)
    }
}
