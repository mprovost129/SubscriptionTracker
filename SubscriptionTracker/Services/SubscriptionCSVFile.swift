import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct SubscriptionCSVFile: Transferable, Sendable {
    let data: Data
    let filename: String

    init(
        csv: String,
        filename: String
    ) {
        self.data = Data(
            ("\u{FEFF}" + csv).utf8
        )
        self.filename = filename
    }

    static var transferRepresentation:
        some TransferRepresentation {
        DataRepresentation(
            exportedContentType: .commaSeparatedText
        ) { file in
            file.data
        }
        .suggestedFileName(\.filename)
    }
}
