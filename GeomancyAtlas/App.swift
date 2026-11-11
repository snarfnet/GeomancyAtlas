import SwiftUI
import UniformTypeIdentifiers

@MainActor final class AtlasStore:ObservableObject {
    @Published var records:[GeomancyRecord]=[]
    @Published var error:String?
    private var failed=false
    private let url:URL
    init(){let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("GeomancyAtlas",isDirectory:true);url=root.appendingPathComponent("records.json")
        do{try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);if FileManager.default.fileExists(atPath:url.path){let r=try JSONDecoder().decode([GeomancyRecord].self,from:Data(contentsOf:url));guard r.count<=500,r.allSatisfy({$0.isValid})else{throw CocoaError(.fileReadCorruptFile)};records=r}}catch{failed=true;self.error="保存データを読み込めません。元のファイルは保持しています。 / Could not read saved data. Original file preserved."}}
    func save(_ r:GeomancyRecord)throws{guard !failed,r.isValid else{throw CocoaError(.fileWriteUnknown)};var next=records;if let i=next.firstIndex(where:{$0.id==r.id}){next[i]=r}else{guard next.count<500 else{throw CocoaError(.fileWriteOutOfSpace)};next.insert(r,at:0)};try persist(next)}
    func remove(_ r:GeomancyRecord)throws{try persist(records.filter{$0.id != r.id})}
    private func persist(_ r:[GeomancyRecord])throws{guard !failed else{throw CocoaError(.fileWriteUnknown)};try JSONEncoder().encode(r).write(to:url,options:.atomic);records=r}
}
@main struct GeomancyAtlasApp:App {var body:some Scene{WindowGroup{AtlasView()}}}
struct AtlasFile:Identifiable{let id=UUID();let url:URL}
struct FigureDots:View {
    let value:Int
    var body:some View{VStack(spacing:7){ForEach(0..<4,id:\.self){row in HStack(spacing:12){ForEach(0..<GeomanticFigure.all[value].rows[row],id:\.self){_ in Circle().frame(width:7,height:7)}}.frame(width:40)}}.frame(height:56).accessibilityLabel(GeomanticFigure.all[value].rows.map(String.init).joined(separator:" "))}
}
struct AtlasView:View {
    @StateObject private var store=AtlasStore()
    @AppStorage("japanese") private var japanese=Locale.current.language.languageCode?.identifier=="ja"
    @State private var record=GeomancyRecord()
    @State private var tab=0
    @State private var step=5
    @State private var selected:Int?
    @State private var detail:Int?
    @State private var search=""
    @State private var share:AtlasFile?
    @State private var removing:GeomancyRecord?
    @State private var importing=false
    @State private var message:String?
    private let navy=Color(red:0.08,green:0.13,blue:0.23)
    private let gold=Color(red:0.86,green:0.73,blue:0.46)
    private func t(_ ja:String,_ en:String)->String{japanese ? ja : en}
    var body:some View{
        NavigationStack{
            VStack(spacing:0){
                HStack(alignment:.firstTextBaseline){VStack(alignment:.leading){Text("Geomancy Atlas").font(.system(size:30,weight:.medium,design:.serif));Text(t("古典ジオマンシー図譜","A study of sixteen figures")).font(.caption).foregroundStyle(gold)};Spacer();Button(japanese ? "EN" : "日本語"){japanese.toggle()}.font(.caption).padding(8).overlay(Capsule().stroke(gold))}.padding(20)
                Picker("Section",selection:$tab){Text(t("図譜","Figures")).tag(0);Text(t("図表を組む","Build")).tag(1);Text(t("記録","Journal")).tag(2);Text(t("読む","Guide")).tag(3)}.pickerStyle(.segmented).padding(.horizontal)
                ScrollView{Group{if tab==0{atlas}else if tab==1{builder}else if tab==2{journal}else{guide}}.padding(20)}
            }.foregroundStyle(.white).background(navy)
                .toolbar(.hidden,for:.navigationBar)
                .sheet(item:$share){AtlasShare(url:$0.url)}
                .sheet(isPresented:Binding(get:{detail != nil},set:{if !$0{detail=nil}})){if let i=detail{figureDetail(i)}}
                .alert(t("記録を削除しますか？","Delete this record?"),isPresented:Binding(get:{removing != nil},set:{if !$0{removing=nil}})){Button(t("削除","Delete"),role:.destructive){if let r=removing{do{try store.remove(r)}catch{message=t("削除できませんでした。","Could not save deletion.")}};removing=nil};Button(t("キャンセル","Cancel"),role:.cancel){removing=nil}}
                .alert(t("お知らせ","Notice"),isPresented:Binding(get:{message != nil || store.error != nil},set:{if !$0{message=nil;store.error=nil}})){Button("OK"){message=nil;store.error=nil}}message:{Text(message ?? store.error ?? "")}
                .fileImporter(isPresented:$importing,allowedContentTypes:[.json]){result in do{let u=try result.get();let access=u.startAccessingSecurityScopedResource();defer{if access{u.stopAccessingSecurityScopedResource()}};let data=try Data(contentsOf:u);guard data.count<100_000 else{throw CocoaError(.fileReadTooLarge)};var r=try JSONDecoder().decode(GeomancyRecord.self,from:data);guard r.isValid else{throw CocoaError(.fileReadCorruptFile)};r.id=UUID();record=r;tab=1;selected=nil}catch{message=t("この記録は読み込めません。","Could not read this record.")}}
        }.preferredColorScheme(.dark).tint(gold)
    }
    private var atlas:some View{
        VStack(alignment:.leading,spacing:20){Text(t("四つの段。十六のかたち。","Four rows. Sixteen figures.")).font(.title2.weight(.medium));TextField(t("名称を検索","Find a figure"),text:$search).textFieldStyle(.roundedBorder)
            LazyVGrid(columns:[GridItem(.adaptive(minimum:145))],spacing:12){ForEach(GeomanticFigure.all.filter{search.isEmpty || ($0.latin+$0.japanese+$0.english).localizedCaseInsensitiveContains(search)}){f in Button{detail=f.id}label:{VStack(spacing:12){FigureDots(value:f.id).foregroundStyle(gold);Text(f.latin).font(.system(.headline,design:.serif));Text(japanese ? f.japanese : f.english).font(.caption).foregroundStyle(.secondary)}.frame(maxWidth:.infinity).padding(.vertical,20).background(.white.opacity(0.05),in:RoundedRectangle(cornerRadius:5))}.buttonStyle(.plain)}}
        }
    }
    private var builder:some View{
        VStack(alignment:.leading,spacing:18){Text(t("母図の点をタップして組む","Tap the Mothers to begin")).font(.title2)
            HStack(alignment:.top){ForEach(0..<4,id:\.self){m in VStack{Text("M\(m+1)").font(.caption.monospaced());ForEach(0..<4,id:\.self){r in Button{record.mothers[m] ^= 1 << (3-r);selected=nil}label:{Text(((record.mothers[m] >> (3-r)) & 1)==1 ? "●" : "● ●").font(.system(size:18)).frame(maxWidth:.infinity).frame(height:36).background(.white.opacity(0.07))}.accessibilityLabel(t("母図\(m+1)の第\(r+1)段","Mother \(m+1), row \(r+1)"))}}}}
            HStack{Button(t("無作為に点を置く","Randomize")){record.mothers=(0..<4).map{_ in Int.random(in:0..<16)};selected=nil};Spacer();Button(t("新しい記録","New record")){record=GeomancyRecord();selected=nil}}
            Picker(t("生成段階","Construction"),selection:$step){ForEach(0..<6,id:\.self){i in Text(t(["母図","娘図","姪図","証人","判定者","追加図"][i],["Mothers","Daughters","Nieces","Witnesses","Judge","Extra"][i])).tag(i)}}
            if let chart=ShieldChart(mothers:record.mothers){
                let groups=[[0,1,2,3],[4,5,6,7],[8,9,10,11],[12,13],[14],[15]]
                ForEach(0...step,id:\.self){row in HStack(alignment:.top,spacing:6){ForEach(groups[row],id:\.self){i in let f=GeomanticFigure.all[chart.figures[i]];Button{selected=i}label:{VStack(spacing:7){Text(ShieldChart.role(i,ja:japanese)).font(.system(size:10)).lineLimit(2);FigureDots(value:f.id).foregroundStyle(gold);Text(f.latin).font(.system(size:10,design:.serif)).lineLimit(2).minimumScaleFactor(0.7)}.frame(maxWidth:.infinity).padding(.vertical,12).background(selected==i ? gold.opacity(0.18) : .white.opacity(0.04),in:RoundedRectangle(cornerRadius:4))}.buttonStyle(.plain)}}}
                if let i=selected{VStack(alignment:.leading,spacing:8){Text(ShieldChart.role(i,ja:japanese)).font(.headline)
                    if let parents=ShieldChart.parents[i]{Text(parents.map{ShieldChart.role($0,ja:japanese)}.joined(separator:" + ")+" → "+GeomanticFigure.all[chart.figures[i]].latin);Text(t("同じ段の点を足します。奇数は1点、偶数は2点です。","Add each matching row: odd becomes one dot; even becomes two."))}else if i>=4{Text(t("各母図の第\(i-3)段を、左から順に縦へ並べています。","Rows \(i-3) of the four Mothers become this Daughter, in order."))}else{Text(t("ここで入力した点が、後の図の出発点です。","This input figure supplies the rows used by later figures."))}
                    Button(t("図の名称を見る","Open figure entry")){detail=chart.figures[i]}
                }.font(.callout).padding().background(.white.opacity(0.05))}
            }
            TextField(t("記録の名前（80字まで）","Record title (up to 80 characters)"),text:$record.title).textFieldStyle(.roundedBorder)
            TextField(t("観察・読み取りのメモ（4000字まで）","Observation notes (up to 4,000 characters)"),text:$record.notes,axis:.vertical).lineLimit(3...8).textFieldStyle(.roundedBorder)
            HStack{Button(t("記録を保存","Save record")){do{try store.save(record);message=t("端末内に保存しました。","Saved on this device.")}catch{message=t("保存できませんでした。文字数・保存件数を確認してください。","Could not save. Check text length and the 500-record limit.")}}.disabled(!record.isValid);Spacer();Menu(t("書き出し","Export")){Button("SVG"){export("svg")};Button("JSON"){export("json")}}.disabled(!record.isValid)}
            Text(t("点の配置と計算を学ぶための図表です。将来の出来事を予測する機能はありません。","A study chart of figures and their construction. It does not predict future events.")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var journal:some View{VStack(alignment:.leading,spacing:16){HStack{Text(t("端末内の記録","Your local journal")).font(.title2);Spacer();Button(t("読み込む","Import")){importing=true}}
        if store.records.isEmpty{Text(t("図表を組んで保存すると、ここに並びます。","Build a chart and save it to start your journal.")).foregroundStyle(.secondary)}
        ForEach(store.records){r in HStack{Button{record=r;selected=nil;tab=1}label:{VStack(alignment:.leading){Text(r.title.isEmpty ? t("名称未設定","Untitled") : r.title);Text(r.date.formatted(date:.abbreviated,time:.omitted)).font(.caption).foregroundStyle(.secondary)}};Spacer();Button(role:.destructive){removing=r}label:{Image(systemName:"trash")}.accessibilityLabel(t("記録を削除","Delete record"))}.padding().background(.white.opacity(0.05))}
    }}
    private var guide:some View{VStack(alignment:.leading,spacing:20){Text(t("図表の読み方を、手順から。","Learn the construction first.")).font(.title2)
        Text(t("四段に1点または2点を置くと、組み合わせは16通りです。最初の四つを母図と呼びます。母図の横の段を取り出して縦に並べ直すと、四つの娘図ができます。","Four rows with one or two dots give sixteen possible figures. The four inputs are Mothers. Transpose their rows to obtain the four Daughters."))
        Text(t("隣り合う図の各段を足し、奇数なら1点、偶数なら2点にします。母図と娘図から姪図、姪図から証人、二つの証人から判定者ができます。本アプリの追加図は、判定者と第一母図から作ります。","Combine neighboring figures row by row: odd sums give one dot, even sums two. This produces Nieces, Witnesses and a Judge. The optional Reconciler combines the Judge and first Mother."))
        Text(t("この試作はラテン語名・和訳・英訳と図形の構築を扱います。惑星対応や吉凶の解釈は流派差があるため、まだ収録していません。","This prototype covers Latin names, Japanese and English glosses, and chart construction. Planetary attributions and interpretive judgments are not yet included."))
        Text(t("資料と編集方針","Sources and editorial scope")).font(.headline)
        Text("Cornelius Agrippa, Three Books of Occult Philosophy, Book II, Chapter 48 (1651 English edition).")
        Link(t("古典の図形一覧を読む","Read the historical figure list"),destination:URL(string:"https://magick.me/library/three-books-of-occult-philosophy/132")!)
        Link(t("生成規則の照合先","Construction cross-reference"),destination:URL(string:"https://geomantia.app/faq")!)
        Text(t("本文は独自に要約し、図形は点の配置から描画しています。資料画像・現代の解説文は転載していません。記録は端末内に保存し、広告・追跡・会員登録はありません。外部リンクはブラウザーで開きます。","Explanations are written for this app; figures are drawn from dot patterns. No manuscript scans or modern commentary are reproduced. Records stay on your device. No ads, tracking or account. External links open in your browser.")).font(.caption).foregroundStyle(.secondary)
    }}
    private func figureDetail(_ i:Int)->some View{let f=GeomanticFigure.all[i];return VStack(spacing:24){FigureDots(value:i).scaleEffect(2).frame(height:120);Text(f.latin).font(.largeTitle);Text(japanese ? f.japanese : f.english).font(.title2);Text(f.rows.map(String.init).joined(separator:" · ")).font(.title.monospaced());Text(t("上から順に各段の点の数を示しています。名称の訳は語義の手がかりです。","Read the dot counts from top to bottom. The translated name is a lexical gloss.")).multilineTextAlignment(.center);Button(t("閉じる","Close")){detail=nil}}.padding(30)}
    private func export(_ ext:String){do{let data:Data;if ext=="svg"{guard let svg=ChartSVG.make(record)else{return};data=Data(svg.utf8)}else{data=try JSONEncoder().encode(record)};let u=FileManager.default.temporaryDirectory.appendingPathComponent("geomancy-\(UUID()).\(ext)");try data.write(to:u,options:.atomic);share=AtlasFile(url:u)}catch{message=t("書き出せませんでした。","Could not export.")}}
}
struct AtlasShare:UIViewControllerRepresentable{let url:URL;func makeUIViewController(context:Context)->UIActivityViewController{UIActivityViewController(activityItems:[url],applicationActivities:nil)};func updateUIViewController(_ v:UIActivityViewController,context:Context){}}
