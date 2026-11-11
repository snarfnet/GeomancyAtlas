import XCTest
import PDFKit
@testable import GeomancyAtlas
final class AtlasRenderTests:XCTestCase{
 @MainActor func testExportAndPersistence()throws{
  let folder=URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("atlas-artifacts",isDirectory:true)
  try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
  var r=GeomancyRecord();r.title="Study of the sixteen figures"
  let png=try XCTUnwrap(ChartPrint.png(r));try png.write(to:folder.appendingPathComponent("chart.png"));XCTAssertEqual(UIImage(data:png)?.size.width,1200)
  let pdf=ChartPrint.pdf(r);try pdf.write(to:folder.appendingPathComponent("chart.pdf"));XCTAssertEqual(PDFDocument(data:pdf)?.pageCount,1)
  try ChartSVG.make(r)!.write(to:folder.appendingPathComponent("chart.svg"),atomically:true,encoding:.utf8)
  let root=folder.appendingPathComponent(UUID().uuidString);let store=AtlasStore(rootOverride:root);try store.save(r);XCTAssertEqual(AtlasStore(rootOverride:root).records,[r])
  r.notes="updated";try store.save(r);XCTAssertEqual(store.records.count,1);XCTAssertEqual(AtlasStore(rootOverride:root).records[0].notes,"updated")
  try store.remove(r);XCTAssertTrue(AtlasStore(rootOverride:root).records.isEmpty)
  let damaged=Data("broken".utf8);try damaged.write(to:root.appendingPathComponent("records.json"));let protected=AtlasStore(rootOverride:root);XCTAssertNotNil(protected.error);XCTAssertThrowsError(try protected.save(r));XCTAssertEqual(try Data(contentsOf:root.appendingPathComponent("records.json")),damaged)
 }
}
