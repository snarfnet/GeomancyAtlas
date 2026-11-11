import Foundation
func check(_ b:Bool,_ s:String){if !b{fatalError(s)}}
check(GeomanticFigure.all.count==16,"catalog")
check(Set(GeomanticFigure.all.map{$0.rows}).count==16,"all patterns distinct")
check(GeomanticFigure.all[0].rows==[2,2,2,2],"Populus")
check(GeomanticFigure.all[15].rows==[1,1,1,1],"Via")
check(ShieldChart(mothers:[0,1,2])==nil,"invalid count")
check(ShieldChart(mothers:[0,1,2,16])==nil,"invalid figure")
// Exhaustively verify all possible four-Mother inputs (16^4).
for packed in 0..<65536 {
 let m=(0..<4).map{(packed >> (4*$0)) & 15};let c=ShieldChart(mothers:m)!
 check(c.figures.count==16,"chart count")
 check(c.figures[14].nonzeroBitCount % 2 == 0,"Judge parity")
 for row in 0..<4 {let expected=(0..<4).reduce(0){$0 | (((m[$1] >> (3-row)) & 1) << (3-$1))};check(c.figures[4+row]==expected,"daughter transposition")}
 // Independent dot-count addition, rather than the implementation XOR.
 for (child,parents) in ShieldChart.parents {let a=GeomanticFigure.all[c.figures[parents[0]]].rows,b=GeomanticFigure.all[c.figures[parents[1]]].rows;let expected=zip(a,b).map{($0+$1)%2==0 ? 2 : 1};check(GeomanticFigure.all[c.figures[child]].rows==expected,"parity addition")}
}
var r=GeomancyRecord();r.title="<script>&\"";check(ChartSVG.make(r)!.contains("&lt;script&gt;&amp;&quot;"),"SVG escaping")
let decoded=try JSONDecoder().decode(GeomancyRecord.self,from:JSONEncoder().encode(r));check(decoded==r,"record roundtrip")
try ChartSVG.make(r)!.write(toFile:CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "/tmp/geomancy.svg",atomically:true,encoding:.utf8)
print("PASS: 65,536 charts, 16 distinct figures, Judge parity, SVG escaping and JSON roundtrip")
