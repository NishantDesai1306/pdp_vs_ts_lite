import "dart:async";
import "dart:convert";
import 'package:flutter/services.dart';
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import 'package:intl/intl.dart';

main() {
	SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
	return runApp(App());
}

class App extends StatelessWidget {
	build(c) => MaterialApp(home: Page());
}

class Page extends StatefulWidget {
	createState() => PageSt();
}

var white=Colors.white;
var style=TextStyle(color: white, fontSize: 25, fontWeight: FontWeight.bold);
messageText(txt) => Text(txt, style: style, textAlign: TextAlign.center);

class Channel {
  var id, name, subs=-1, img, desc='', color;
  Channel(this.id, this.name, this.img, this.color);
}

class PageSt extends State {
  var ts=Channel("UCq-Fj5jknLsUf-MWSy4_brA", "T-Series", Image.asset("img/ts.png"),Colors.red[900]),
			pdp=Channel("UC-lHJZR3Gqxm24_Vd_AJ5Yw", "PewDiePie", Image.asset("img/pdp.png"), Colors.blue[900]);
	var timer, loading=true;
	var bR=BorderRadius.circular(15), allSides=EdgeInsets.all(15);

	PageSt() {
		Timer.periodic(Duration(seconds: 3), (t) async {
			timer=t;
			var newTSubs=await getSubs(ts.id), newPSubs=await getSubs(pdp.id);

      if (loading) {
        ts.desc = await rootBundle.loadString('txt/ts.txt');
        pdp.desc = await rootBundle.loadString('txt/pdp.txt');
      }

			setState(() {
				ts.subs=newTSubs;
        pdp.subs=newPSubs;
				loading=false;
			});
		});
	}

	// logic
	getSubs(id) async {
		var res, url="https://www.googleapis.com/youtube/v3/channels?id=$id&part=statistics&key=AIzaSyDvd7sKFtV7evDIlkFmTCrWUIsCEWu1aJY";

		try {
			res=await http.get(url);
		}
		catch (e) { print(e); }

		if (res!=null && res.statusCode==200) {
			res=json.decode(res.body);
			var data=res["items"][0];
			return data!=null ? num.parse(data["statistics"]["subscriberCount"]) : -1;
		}

		return -1;
	}

	Widget channelUI(c) {
		var rounded = (w) => ClipRRect(child: w, borderRadius: bR);

		return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.only(bottom: 10),
      child: Card(
        color: c.color,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: bR),
        child: rounded(ExpansionTile(
					title: Row(
						children: [
							Container(
								margin: EdgeInsets.symmetric(vertical: 12), height: 135,
								child: rounded(c.img)
							),
							Expanded(
								child: Container(padding: allSides, child: Counter(v: c.subs, sfx: ' subscribers'))
							)
						]
					),
					children: [Container(
						margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
						child: Text(c.desc, style: TextStyle(color: white, fontSize: 18))
					)],
					trailing: Container(width: 0),
				))
      )
    );
	}

	build(ctxt) {
		var screenH=MediaQuery.of(ctxt).size.height, cardsH=181*2+15.0; // 181 is height of card and 15 is bottom padding
		var d=ts.subs-pdp.subs, internet= ts.subs>0 && pdp.subs>0, msg;
		var bgColor= internet||loading ? Colors.blue[700] : Colors.red[700];
		Widget icon=Container();
		List<Widget> widgets=(d>0 ? [ts, pdp] : [pdp, ts]).map(channelUI).toList();

		if (!internet) {
			widgets=[];
			cardsH=0;
			icon=Icon(Icons.warning, color: white);
			msg="Can't access Internet";
		}

		if (loading) {
			widgets=[];
			cardsH=0;
			icon=CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(white));
			msg="Loading";
		}

		widgets.insert(0, Container(
			height: screenH - cardsH,
			alignment: Alignment.center,
			child: Wrap(children: [
				icon,
				msg!=null ? messageText("   $msg") : Counter(v: d.abs(), pfx: (d>0 ? ts.name : pdp.name) + " is ahead by ", sfx: " subscribers")
			])
		));

		return Scaffold(
			backgroundColor: bgColor,
			body: SingleChildScrollView(child: Column(children: widgets))
		);
	}

	dispose() {
		timer.cancel();
		super.dispose();
	}
}

class Counter extends StatefulWidget {
	var v, sfx, pfx;
	Counter({this.v=0, this.pfx='', this.sfx=''});
	CounterSt createState() => CounterSt(v);
}

class CounterSt extends State<Counter> {
	var cnt, fv, tmr, nf=NumberFormat.simpleCurrency(decimalDigits: 0, name: 'JPY', locale: 'en_US');
	CounterSt(v) { fv = cnt = v; }

	didUpdateWidget(ow) {
		if (tmr!=null) {
			tmr.cancel();
			setState(() {cnt = fv;});
		}
		fv = ow!= null? ow.v : widget.v;
		tmr = Timer.periodic(Duration(milliseconds: 100), updateCnt);
		super.didUpdateWidget(ow);
	}

	updateCnt(timer) {
		var nv=0, d=fv-cnt;
		if (d==0) {
			timer.cancel();
			return;
		}
		else {
			nv=d<0 ? cnt-1 : cnt+1;
		}
		setState(() { cnt=nv; });
	}

	build(c) => messageText((widget.pfx ?? '') + nf.format(cnt).substring(1) + (widget.sfx ?? ''));
}
