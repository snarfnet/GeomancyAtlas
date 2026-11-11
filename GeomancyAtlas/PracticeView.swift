import SwiftUI

struct PracticeView:View {
    let japanese:Bool
    @State private var left=15
    @State private var right=3
    @State private var question=0
    @State private var choices=[0,3,10,15]
    @State private var answer:Int?
    @State private var correct=0
    @State private var attempted=0
    private func t(_ a:String,_ b:String)->String{japanese ? a : b}
    var body:some View{VStack(alignment:.leading,spacing:22){
        Text(t("図形の演算台","Figure workshop")).font(.title2)
        Picker(t("左の図","Left figure"),selection:$left){ForEach(GeomanticFigure.all){f in Text(f.latin).tag(f.id)}}
        Picker(t("右の図","Right figure"),selection:$right){ForEach(GeomanticFigure.all){f in Text(f.latin).tag(f.id)}}
        HStack{symbol(left);Text("+");symbol(right);Text("=");symbol(left ^ right)}
        ForEach(0..<4,id:\.self){row in let a=GeomanticFigure.all[left].rows[row],b=GeomanticFigure.all[right].rows[row];Text("\(row+1):  \(a) + \(b) = \(a+b)  →  \((a+b)%2==0 ? 2 : 1)").font(.body.monospaced())}
        Text(t("各段の合計が奇数なら1点、偶数なら2点。同じ図を足すと、必ずPopulusになります。","Odd row sums become one dot; even sums become two. Combining a figure with itself always yields Populus.")).font(.callout)
        HStack{Button(t("点の数を反転","Invert dots")){left ^= 15};Spacer();Button(t("上下を反転","Reverse rows")){left=GeomanticFigure.all[left].rows.reversed().reduce(0){($0 << 1) | ($1==1 ? 1 : 0)}}}
        Divider()
        Text(t("名称を覚える","Learn the names")).font(.title2)
        FigureDots(value:question).scaleEffect(1.5).frame(maxWidth:.infinity).frame(height:100)
        ForEach(choices,id:\.self){choice in Button{guard answer==nil else{return};answer=choice;attempted+=1;if choice==question{correct+=1}}label:{HStack{Text(GeomanticFigure.all[choice].latin);Spacer();if let answer=answer,choice==question{Image(systemName:"checkmark.circle.fill")}else if answer==choice{Image(systemName:"xmark.circle")}}.padding(12).background(.white.opacity(0.07),in:RoundedRectangle(cornerRadius:5))}.buttonStyle(.plain).disabled(answer != nil)}
        if answer != nil{Text(t("答え：","Answer: ")+GeomanticFigure.all[question].latin);Button(t("次の図へ","Next figure")){next()}}
        Text(t("正解 \(correct) / \(attempted)問","Correct: \(correct) / \(attempted)")).font(.caption).foregroundStyle(.secondary)
    }.onAppear{if attempted==0 && answer==nil{next()}}}
    private func symbol(_ value:Int)->some View{VStack(spacing:10){FigureDots(value:value);Text(GeomanticFigure.all[value].latin).font(.caption).multilineTextAlignment(.center)}.frame(maxWidth:.infinity)}
    private func next(){question=Int.random(in:0..<16);choices=Array((0..<16).filter{$0 != question}.shuffled().prefix(3))+[question];choices.shuffle();answer=nil}
}

enum ChartPrint {
    static func draw(_ record:GeomancyRecord) {
        guard let chart=ShieldChart(mothers:record.mothers)else{return}
        UIColor.white.setFill();UIRectFill(CGRect(x:0,y:0,width:600,height:720))
        let ink=UIColor(red:0.08,green:0.13,blue:0.23,alpha:1)
        func text(_ value:String,_ rect:CGRect,_ size:CGFloat){(value as NSString).draw(with:rect,options:.usesLineFragmentOrigin,attributes:[.font:UIFont.systemFont(ofSize:size),.foregroundColor:ink],context:nil)}
        text("Geomancy Atlas",CGRect(x:24,y:16,width:550,height:30),22)
        text(record.title,CGRect(x:24,y:50,width:550,height:40),12)
        let groups=[[0,1,2,3],[4,5,6,7],[8,9,10,11],[12,13],[14,15]]
        for (row,indices) in groups.enumerated(){for (column,i) in indices.enumerated(){
            let x=300+(column*2-indices.count+1)*70,y=105+row*115,f=GeomanticFigure.all[chart.figures[i]]
            text(ShieldChart.role(i,ja:false),CGRect(x:x-60,y:y,width:125,height:26),10)
            ink.setFill()
            for (r,n) in f.rows.enumerated(){for d in 0..<n{let cx=x+(n==1 ? 0 : (d==0 ? -8 : 8));UIBezierPath(ovalIn:CGRect(x:cx-3,y:y+25+r*12,width:6,height:6)).fill()}}
            text(f.latin,CGRect(x:x-60,y:y+77,width:125,height:28),11)
        }}
        text("Historical study chart / Reconciler = Judge + Mother 1",CGRect(x:24,y:695,width:550,height:15),8)
    }
    static func png(_ record:GeomancyRecord)->Data?{let f=UIGraphicsImageRendererFormat();f.scale=2;f.opaque=true;return UIGraphicsImageRenderer(size:CGSize(width:600,height:720),format:f).image{_ in draw(record)}.pngData()}
    static func pdf(_ record:GeomancyRecord)->Data{UIGraphicsPDFRenderer(bounds:CGRect(x:0,y:0,width:600,height:720)).pdfData{c in c.beginPage();draw(record)}}
}
