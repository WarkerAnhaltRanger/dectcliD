module helloworld;

import DectDeviceStructs;
import DectDevice;

import tango.io.Stdout;
import tango.text.convert.Integer;
import tango.text.Util;
import tango.stdc.time;


ubyte[] parseRFPI(char[] rfpiStr)
{
	ubyte[] tempRFPI = new ubyte[5];
	char[10] cleanedRFPI;
	ushort i = 0;
	ushort pos = 0;
	
	for(i = 0; i < rfpiStr.length && pos < cleanedRFPI.length; i++)
	{
		if(rfpiStr[i] != ':')
		{
			cleanedRFPI[pos] = rfpiStr[i];
			pos++;
		}		
	}
	
	pos=0;
	
	for(i = 0; i < cleanedRFPI.length-1; i+=2)
	{
		tempRFPI[pos] = Integer.parse(cleanedRFPI[i..(i+2)], 16);
		pos++;
	}
	//Stdout.formatln("{0:x}", tempRFPI);
	
	return tempRFPI;
}

int main(char[][] args)
{
	auto COA = new DectDevice("/dev/coa",1000);

	time_t lasttime = 0;
	time_t timeout = 10;
	
	ubyte[5] RFPI;
	
	if(args.length == 2)
	{
		RFPI[] = parseRFPI(args[1])[0..5];
		Stdout.formatln("Versuche Basisstation {0:X} zu finden ",RFPI);
	}
	
	Stdout.formatln("Aktive Basisstationen: ");
	for(uint chan = 0; chan <= 9; chan++)
	{
		
	
		foreach(station; COA.Fpscan())
		{
			Stdout.formatln("Basisstation {0:X} auf Carrier {1} RSSI {2}",station.RFPI, station.Channel, station.RSSI);
		}
		
		COA.Channelhop();
	}
	
	
	while(0xDEC + 'T') 
	{
		if(args.length == 2)
		{
			COA.autorec(RFPI);
		}
		else
			COA.autorec();
	}
	
	scope(exit)
	{
		COA.closeDevice();
	}
	return 0;
}	
