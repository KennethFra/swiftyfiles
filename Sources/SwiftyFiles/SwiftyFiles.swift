import Foundation

public enum AppDirectory : String
{
    case mPDFDocuments = "Library/Documents"
    case documents = "Documents"
    case inbox = "Inbox"
    case library = "Library"
    case bundle = "Bundle"
    case temp = "tmp"

    var url: URL {
        switch self {
        case .bundle:
            return bundle
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

    var bundle: URL {
        Bundle.main.bundleURL
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

public extension URL {
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


public protocol FileActions
{
    func create()

    func write(data: Data, to path: AppDirectory, withName name: String) -> Bool

    func read(at path: AppDirectory, withName name: String) -> Data

    func delete(at path: AppDirectory, withName name: String) -> Bool

    func rename(at path: AppDirectory, with oldName: String, to newName: String) -> Bool

    func move(withName name: String, inDirectory: AppDirectory, toDirectory directory: AppDirectory) -> Bool

    func copy(withName name: String, inDirectory: AppDirectory, toDirectory directory: AppDirectory) -> Bool
}

public class mPDFFileManager {
    public static let `default` = mPDFFileManager()

    public init() {}

    public func write(data: Data, to path: AppDirectory, withName name: String) -> Bool {
        return false
    }

//    func rename(at path: AppDirectory, with oldName: String, to newName: String) -> Bool {
//        return bool
//    }

//    func move(withName name: String, inDirectory: AppDirectory, toDirectory directory: AppDirectory) -> Bool

    public func copy(from: mPDFFile, to: mPDFFile) throws {
        try FileManager.default.copyItem(at: from.url, to: to.url)
    }
}

public  class mPDFFile {
    let root: AppDirectory
    let parentPath: String
    let filename: String

    public init(root: AppDirectory, parentPath: String, filename: String = "") {
        self.root = root
        self.parentPath = parentPath
        self.filename = filename
    }

    public var url: URL {
        return URL(fileURLWithPath: parentPath, relativeTo: root.url).appendingPathComponent(filename)
    }

    func createParentFolder() throws {
        let url = root.url.appendingPathComponent(parentPath)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}

public class mPDFDirectory: mPDFFile {
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

    public init(root: AppDirectory, parentPath: String = "") {
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
