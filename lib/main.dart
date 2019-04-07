import "dart:async";
import "dart:convert";
import 'package:flutter/services.dart';
import "package:flutter/material.dart";
import "package:http/http.dart";
import 'package:intl/intl.dart';

main() {
	SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);

	return runApp(App());
}

class App extends StatelessWidget {
	build(c) => MaterialApp(
		home: Page(), 
		theme: ThemeData(
      accentColor: Colors.white,
      dividerColor: Colors.transparent,
      brightness: Brightness.dark
    )
	);
}

class Page extends StatefulWidget {
	createState() => PageSt();
}

class MessageText extends StatelessWidget {
	final txt;
	
  MessageText(this.txt);
	
  build(c) => Text(
    txt,
    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
    textAlign: TextAlign.center
  );
}

class Channel {
	var id, name, subs=-1, img, desc='', color;
	Channel(this.id, this.name, this.img, this.color);
}

class PageSt extends State {
	var ts = Channel("UCq-Fj5jknLsUf-MWSy4_brA", "T-Series", Image.asset("img/ts.png"), Colors.red[900]),
			pdp = Channel("UC-lHJZR3Gqxm24_Vd_AJ5Yw", "PewDiePie", Image.asset("img/pdp.png"), Colors.blue[900]),
      timer,
      loading = true,
      bR = BorderRadius.circular(15),
      UPDATE_FREQUENCY = 3;

	PageSt() {
		Timer.periodic(Duration(seconds: UPDATE_FREQUENCY), (t) async {
			timer = t;
			var newTSubs = await getSubs(ts.id), newPSubs = await getSubs(pdp.id);

			if (loading) {
				ts.desc = await rootBundle.loadString('txt/ts.txt');
				pdp.desc = await rootBundle.loadString('txt/pdp.txt');
			}

			setState(() {
				ts.subs = newTSubs;
				pdp.subs = newPSubs;
				loading = false;
			});
		});
	}

	getSubs(id) async {
		var res, url = "https://www.googleapis.com/youtube/v3/channels?id=$id&part=statistics&key=AIzaSyDvd7sKFtV7evDIlkFmTCrWUIsCEWu1aJY";

		try {
			res = await get(url);
		}
		catch (e) { print(e); }

		if (res != null && res.statusCode == 200) {
			res = json.decode(res.body);
			var data = res["items"][0];
			return data != null ? num.parse(data["statistics"]["subscriberCount"]) : -1;
		}

		return -1;
	}

	Widget channelUI(c) {
		var rounded = (w) => ClipRRect(child: w, borderRadius: bR);
		var icon = Container(
			margin: EdgeInsets.only(top: 12, bottom: 12, right: 12),
			height: 125,
			child: rounded(c.img)
		);
		var subTxt = Expanded(child: Counter(val: c.subs, suffix: " subscribers"));
		var expanded = Container(
			padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
			child: Text(c.desc, style: TextStyle(fontSize: 18))
		);

		return Container(
			padding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
			child: Card(
				color: c.color, shape: RoundedRectangleBorder(borderRadius: bR),
				child: Container(
					padding: EdgeInsets.all(10),
					child: rounded(ExpansionTile(
						title: Row(children: [icon, subTxt]),
						children: [expanded],
						trailing: Container(width: 0)
					)),
				),
			)
		);
	}

	build(ctxt) {
		var screenH = MediaQuery.of(ctxt).size.height,
      cardsH = 207*2.0, // 210 is height of card and 15 is bottom padding
		  d = ts.subs-pdp.subs,
      internet= ts.subs>0 && pdp.subs>0,
      bgColor= internet || loading ? Colors.blue[700] : Colors.red[700],
      widgets=(d > 0 ? [ts, pdp] : [pdp, ts]).map(channelUI).toList(),
      msg;
		Widget icon=Container();

		if (!internet) {
			widgets = [];
			cardsH = 0;
			icon = Icon(Icons.error, size: 30);
			msg = "Can't access Internet";
		}

		if (loading) {
			widgets = [];
			cardsH = 0;
			icon = CircularProgressIndicator();
			msg = "Loading";
		}

		widgets.insert(0, Container(
			height: screenH - cardsH,
			alignment: Alignment.center,
			child: Wrap(children: [
				icon,
				msg != null ? MessageText("  $msg") : Counter(val: d.abs(), prefix: (d>0 ? ts.name : pdp.name) + " is ahead by ", suffix: " subscribers")
			])
		));

		return Scaffold(
			backgroundColor: bgColor,
			body: SingleChildScrollView(
        child: Column(children: widgets)
      )
		);
	}
}

class Counter extends StatefulWidget {
	var val, suffix, prefix;
	Counter({this.val = 0, this.prefix = '', this.suffix = ''});
	CounterSt createState() => CounterSt(val);
}

class CounterSt extends State<Counter> {
	var cnt, fv, tmr, nf = NumberFormat.simpleCurrency(decimalDigits: 0, name: 'USD');

	CounterSt(v) {
		fv = cnt = v;
	}

	didUpdateWidget(ow) {
		if (tmr!=null) {
			tmr.cancel();
			setState(() {
				cnt = fv;
			});
		}

		fv = ow!=null ? ow.val : widget.val;
		tmr=Timer.periodic(Duration(milliseconds: 100), updateCnt);
		super.didUpdateWidget(ow);
	}

	updateCnt(timer) {
		var nv = 0, d = fv - cnt;

		if (d == 0) {
			return timer.cancel();
		}
		else {
			nv= d < 0 ? cnt - 1 : cnt + 1;
		}

		setState(() {
			cnt = nv;
		});
	}

	build(c) => MessageText((widget.prefix ?? '') + nf.format(cnt).substring(1) + (widget.suffix ?? ''));
}
