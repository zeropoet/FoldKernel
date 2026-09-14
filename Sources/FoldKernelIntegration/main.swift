import FoldKernel
import Foundation

private let arguments = Array(CommandLine.arguments.dropFirst())

do {
    guard let command = arguments.first else { throw CommandError.usage }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

    switch command {
    case "conformance":
        print(String(decoding: try encoder.encode(FoldKernelIntegrationContract.conformanceReport()), as: UTF8.self))
    case "verify":
        guard arguments.count == 8,
              arguments[2] == "--source-commit",
              arguments[4] == "--verified-at",
              arguments[6] == "--output" else { throw CommandError.usage }
        let declarationURL = URL(fileURLWithPath: arguments[1])
        let receipt = try FoldKernelIntegrationContract.createReceipt(
            declarationData: Data(contentsOf: declarationURL),
            sourceCommit: arguments[3],
            verifiedAt: arguments[5]
        )
        var data = try encoder.encode(receipt)
        data.append(0x0a)
        try data.write(to: URL(fileURLWithPath: arguments[7]), options: .atomic)
        print("valid=true")
        print("consumer=\(receipt.consumer.name)")
        print("source_commit=\(receipt.sourceCommit)")
        print("checks_passed=\(receipt.checksPassed)")
    default:
        throw CommandError.usage
    }
} catch {
    FileHandle.standardError.write(Data("\(error.localizedDescription)\n".utf8))
    exit(1)
}

private enum CommandError: Error, LocalizedError {
    case usage

    var errorDescription: String? {
        "Usage: fold-kernel-integration conformance | verify DECLARATION --source-commit SHA --verified-at ISO8601 --output RECEIPT"
    }
}
