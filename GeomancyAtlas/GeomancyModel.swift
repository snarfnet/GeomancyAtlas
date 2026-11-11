import Foundation

struct GeomanticFigure:Identifiable,Equatable {
    let id:Int,latin:String,japanese:String,english:String
    var rows:[Int] {(0..<4).map{(id & (1 << (3-$0))) == 0 ? 2 : 1}}
    static let all:[GeomanticFigure] = [
        .init(id:0,latin:"Populus",japanese:"人々",english:"People"),
        .init(id:1,latin:"Tristitia",japanese:"悲しみ",english:"Sorrow"),
        .init(id:2,latin:"Albus",japanese:"白",english:"White"),
        .init(id:3,latin:"Fortuna Major",japanese:"大いなる幸運",english:"Greater fortune"),
        .init(id:4,latin:"Rubeus",japanese:"赤",english:"Red"),
        .init(id:5,latin:"Acquisitio",japanese:"獲得",english:"Gain"),
        .init(id:6,latin:"Conjunctio",japanese:"結合",english:"Joining"),
        .init(id:7,latin:"Caput Draconis",japanese:"竜の頭",english:"Dragon's head"),
        .init(id:8,latin:"Laetitia",japanese:"喜び",english:"Joy"),
        .init(id:9,latin:"Carcer",japanese:"牢獄",english:"Prison"),
        .init(id:10,latin:"Amissio",japanese:"喪失",english:"Loss"),
        .init(id:11,latin:"Puella",japanese:"少女",english:"Girl"),
        .init(id:12,latin:"Fortuna Minor",japanese:"小さな幸運",english:"Lesser fortune"),
        .init(id:13,latin:"Puer",japanese:"少年",english:"Boy"),
        .init(id:14,latin:"Cauda Draconis",japanese:"竜の尾",english:"Dragon's tail"),
        .init(id:15,latin:"Via",japanese:"道",english:"Way")
    ]
}
struct ShieldChart:Equatable {
    let figures:[Int]
    init?(mothers:[Int]) {
        guard mothers.count==4,mothers.allSatisfy({(0..<16).contains($0)}) else{return nil}
        var f=mothers
        for row in 0..<4{var daughter=0;for mother in 0..<4{daughter |= ((mothers[mother] >> (3-row)) & 1) << (3-mother)};f.append(daughter)}
        for (a,b) in [(0,1),(2,3),(4,5),(6,7),(8,9),(10,11),(12,13),(14,0)] {f.append(f[a] ^ f[b])}
        figures=f
    }
    static let parents:[Int:[Int]]=[8:[0,1],9:[2,3],10:[4,5],11:[6,7],12:[8,9],13:[10,11],14:[12,13],15:[14,0]]
    static func role(_ i:Int,ja:Bool)->String {
        if i<4{return (ja ? "母図 " : "Mother ")+String(i+1)}
        if i<8{return (ja ? "娘図 " : "Daughter ")+String(i-3)}
        if i<12{return (ja ? "姪図 " : "Niece ")+String(i-7)}
        if i<14{return (ja ? "証人 " : "Witness ")+String(i-11)}
        return i==14 ? (ja ? "判定者" : "Judge") : (ja ? "調停者（追加図）" : "Reconciler (optional)")
    }
}
struct GeomancyRecord:Identifiable,Codable,Equatable {
    var id=UUID(),date=Date(),title="",notes=""
    var mothers=[15,0,3,12]
    var isValid:Bool {title.count<=80 && notes.count<=4000 && ShieldChart(mothers:mothers) != nil}
}
enum ChartSVG {
    static func make(_ record:GeomancyRecord)->String? {
        guard record.isValid,let chart=ShieldChart(mothers:record.mothers)else{return nil}
        func escaped(_ s:String)->String{s.replacingOccurrences(of:"&",with:"&amp;").replacingOccurrences(of:"<",with:"&lt;").replacingOccurrences(of:">",with:"&gt;").replacingOccurrences(of:"\"",with:"&quot;")}
        var s="<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1200\" height=\"1300\" viewBox=\"0 0 1200 1300\"><rect width=\"1200\" height=\"1300\" fill=\"#fafafa\"/><g fill=\"#172238\" font-family=\"sans-serif\"><text x=\"40\" y=\"55\" font-size=\"28\">Geomancy Atlas</text><text x=\"40\" y=\"90\" font-size=\"18\">\(escaped(String(record.title.prefix(50))))</text>"
        let groups=[[0,1,2,3],[4,5,6,7],[8,9,10,11],[12,13],[14,15]]
        for (r,indices) in groups.enumerated(){for (column,i) in indices.enumerated(){let cx=600+(column*2-indices.count+1)*140, y=150+r*220;let f=GeomanticFigure.all[chart.figures[i]]
            s+="<text x=\"\(cx)\" y=\"\(y)\" text-anchor=\"middle\" font-size=\"16\">\(ShieldChart.role(i,ja:false))</text>"
            for (row,dots) in f.rows.enumerated(){for dot in 0..<dots{let x=cx+(dots==1 ? 0 : (dot==0 ? -16 : 16));s+="<circle cx=\"\(x)\" cy=\"\(y+28+row*24)\" r=\"6\"/>"}}
            s+="<text x=\"\(cx)\" y=\"\(y+137)\" text-anchor=\"middle\" font-size=\"17\">\(f.latin)</text>"
        }}
        s+="<text x=\"40\" y=\"1280\" font-size=\"14\">Historical study chart / 1 = odd, 2 = even / Reconciler = Judge + Mother 1</text></g></svg>";return s
    }
}
