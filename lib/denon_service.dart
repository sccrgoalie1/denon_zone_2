

import 'package:denon_zone_2/basic_info.dart';
import 'package:http/http.dart' as http;
import 'package:denon_zone_2/globals.dart';
import 'package:xml/xml.dart';

class DenonService {
  Future<bool> zone2PoweredOn() async {
    http.Client client = new http.Client();
    final response = await client.get(
        'https://${Globals.api_address}:10443/ajax/globals/get_config?type=4',
        headers: {
          'Accept': 'text/plain'
        });
    if (response.statusCode == 200) {
      if (response != null && response.body.isNotEmpty) {
        final xml = XmlDocument.parse(response.body);
        final elements = xml.findElements('listGlobals');
        for (var child in elements.first.children)
        {
          if (child is XmlElement && child.name.local == 'Zone2') {
              return child.firstChild.text == "1";
          }
        }
      }
    }
    return false;
  }

  Future<BasicInfo> getInfo() async {
    BasicInfo info = new BasicInfo();
    http.Client client = new http.Client();
    final String request = '''<?xml version="1.0" encoding="utf-8" ?>
                            <tx>
                            <cmd id="1">GetAllZonePowerStatus</cmd>
                            <cmd id="1">GetAllZoneVolume</cmd>
                            <cmd id="1">GetAllZoneMuteStatus</cmd>
                            <cmd id="1">GetAllZoneSource</cmd>
                            </tx>
                            ''';
    final response = await client.post(
        'http://${Globals.api_address}:8080/goform/AppCommand.xml',
        body: request,
        headers: {
          'Accept': 'text/xml'
        });
    if (response.statusCode == 200) {
      if (response != null && response.body.isNotEmpty) {
        final xml = XmlDocument.parse(response.body.replaceAll('\n',''));
        final elements = xml.findElements('rx');
        for (var i = 0; i < elements.first.children.length; i++) {
          final child = elements.first.children[i];
          if (i == 0) {
            for (var pe in child.children) {
              if (pe is XmlElement && pe.name.local == 'zone1') {
                info.zone1On = pe.text == "ON";
              }
              if (pe is XmlElement && pe.name.local == 'zone2') {
                info.zone2On = pe.text == "ON";
              }
            }

          }
          else if (i == 1) {
            for (var pe in child.children) {
              if (pe is XmlElement && pe.name.local == 'zone2') {
                for (var z2v in pe.children) {
                  if (z2v is XmlElement && z2v.name.local == 'dispvalue') {
                    if (z2v.text == '--')
                      info.zone2Volume =  0;
                    else
                      info.zone2Volume = double.parse(z2v.text.trim());
                  }
                }

              }
            }
          }
          else if (i == 0) {

          }
          else if (i == 0) {

          }
        }

//    <?xml version="1.0" encoding="utf-8" ?>
//    <rx>
//    <cmd>
//    <zone1>ON</zone1>
//    <zone2>ON</zone2>
//    </cmd>
//    <cmd>
//    <zone1>
//    <volume>-34.5</volume>
//    <state>variable</state>
//    <limit>OFF</limit>
//    <disptype>ABSOLUTE</disptype>
//    <dispvalue>45.5</dispvalue>
//    </zone1>
//    <zone2>
//    <volume>-41</volume>
//    <state>variable</state>
//    <limit>-10.0</limit>
//    <disptype>ABSOLUTE</disptype>
//    <dispvalue> 39</dispvalue>
//    </zone2>
//    </cmd>
//    <cmd>
//    <zone1>off</zone1>
//    <zone2>off</zone2>
//    </cmd>
//    <cmd>
//    <zone1>
//    <source>SAT/CBL</source>
//    </zone1>
//    <zone2>
//    <source>SOURCE</source>
//    </zone2>
//    </cmd>
//    </rx>
        return info;
      }
    }
  }

  Future<double> zone2Volume(double volume) async {
    var relativeVolume = (volume - 80).toInt();
    http.Client client = new http.Client();
    final response = await client.get(
        'http://${Globals.api_address}:8080/goform/formiPhoneAppVolume.xml?2+$relativeVolume.0',
        headers: {
          'Accept': 'text/plain'
        });
    if (response.statusCode == 200) {
      final info = await getInfo();
      return info.zone2Volume;
    }
    return 0;
  }

  Future<bool> powerOn() async {
    http.Client client = new http.Client();
    final response = await client.get(
        'https://${Globals.api_address}:10443/ajax/globals/set_config?type=4&data=<Zone2><Power>1</Power></Zone2>',
        headers: {
          'Accept': 'text/plain'
        });

    if (response.statusCode == 200) {
      return true;
    }
    return false;


}
  Future<bool> powerOff() async {
    http.Client client = new http.Client();
    final response = await client.get(
        'https://${Globals.api_address}:10443/ajax/globals/set_config?type=4&data=<Zone2><Power>3</Power></Zone2>',
        headers: {
          'Accept': 'text/plain',
        });
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

}