module DectDevice;

import MyDevice;
import DectDeviceStructs;
import PcapStructs;
import PcapObject;

import tango.io.Stdout;
import tango.io.stream.Format;
import tango.stdc.posix.fcntl;
import STDC = tango.stdc.string;
import tango.stdc.time;
import Integer = tango.text.convert.Integer;

static FormatOutput!(char) delegate(char[],...) LOG;
static this()
{
	LOG = &Stdout.formatln;
}


class DectDevice : MyDevice
{
	protected	int 			ActiveState;
	protected	uint 			Channel;
	protected	ubyte 			Band;
	private 	packet			Packet;
	private		PcapObject		Pcap;
		
	this(char[] DevicePath, uint milliseconds)
	{
		super(DevicePath, milliseconds);
		
		open(O_RDONLY | O_NONBLOCK);
		
		setStopMode();
		
		this.Band 			= BAND_EMEA;
		this.Channel 		= 0;
		this.Pcap			= null;
	}
		
	/*
	 * Setzt den Idle-modus der Karte und stoppt aktive Pcap dumps
	 * Gibt true bei erfolgreichem setzen des Idle-modus zurück
	 */
	bool setStopMode()
	{
		LOG("stoppe DIP");
		stopPcap();
		return setMode(MODE_STOP, COA_MODE_IDLE);
	}
	
	/*
	 * Hilfsfunktion für das Erstellen eines Stationsobjektes
	 * aus einem Buffer
	 * Gibt das erstellte StationsObjekt zurück
	 * NOTE: buf muss 7bytes lang sein
	 */
	Station createStation(ubyte[] buf)
	{
		Station res;
		
		if(buf.length == 7)
		{
			res = createStation(buf[2..7], buf[0], buf[1]);
		}
		return res;
	}
	
	/*
	 * Hilfsfunktion für das Erstellen eines Stationsobjektes
	 */
	Station createStation(ubyte[] RFPI, ubyte Channel, ubyte RSSI, ubyte Type = TYPE_PP)
	{
		//LOG("create_Station");
		
		Station res;
		
		if(RFPI.length != 5)
			res.RFPI[] = 0;
		else
			res.RFPI[] = RFPI[0..5];
		
		res.Channel = Channel;
		res.RSSI = RSSI;
		res.Type = Type;		
		return res;
	}
	
	/*
	 * Funktion die überprüft ob in dem Empfangenen Paket das B-Feld (B-Kanal)
	 * aktiviert wurde. Dieses Feld ist nur aktiviert wenn Daten (z.B. Sprache) versendet werden.
	 * Gibt true zurück wenn in dem aktuellen Paket ein B-Feld festgestellt wurde. 
	 */
	bool hasBField()
	{
		if((Packet.data[5] & 0x0e) != 0x0e)
		{
			//LOG("BField gefunden");
			return true;
		}
		return false;
	}
	
	/*
	 * Die Funktion setChannel setzt den Carrier auf den im Parameter channel beschriebenen.
	 * Valide Kanäle für EMEA 0-9
	 * Valide Kanäle für US DECT 23-27
	 * 
	 * Gibt true zurück wenn der Carrier erfolgreich geändert wurde.
	 * 
	 * NOTE: Wenn der Aktive Modus MODE_STOP ist dann führt ioctl zu einem Fehler
	 */
	bool setChannel(uint channel)
	{	
		if(channel < 0 || channel > 27 || (channel < 23 && channel > 9))
		{
			LOG("WARNUNG: Kanal ausserhalb der Range: {}", channel);
			if(Band == BAND_US)
				channel = 23;
			else
				channel = 0;
		}
			
		if(ActiveState == MODE_STOP)
		{
			LOG("WARNUNG: Karte befindet sich im MODE_STOP kann den channel nicht setzen");
			return false;
		}
			
		//LOG("setChannel auf {}",channel);
		
		if(!sendIoctl(COA_IOCTL_CHAN,channel))
		{
			LOG("ERROR: Konnte Channel nicht setzen");
			return false;
		}
		
		this.Channel = channel;
		
		return true;
	}
	
	/*
	 * Die Funktion setBand ändert das aktuelle Band in das in Band angegebene.
	 * Gibt true bei erfolgreicher Änderung des Bands zurück.
	 */
	bool setBand(ubyte Band)
	{
		LOG("change_Band {0:X}",Band);
		
		switch(Band)
		{
		case BAND_EMEA:
		case BAND_EMEA_US:
			this.Band = Band;
			return setChannel(0);
			
		case BAND_US:
			this.Band = Band;
			return setChannel(23);
			
		default:
			LOG("ERROR: Ungültiges Band angegeben");
			return false;
		}
		
		return false;
	}
	
	/*
	 * Springt im definiertem Band einen Carrier weiter.
	 * Wenn der Carrier am Ende des Carrierbereiches angekommen ist
	 * so wird dieser auf den Anfang zurück gesetzt.
	 * Gibt true zurück wenn der Carrier erfolgreich gesetzt wurde.
	 */
	bool Channelhop()
	{
		uint chan = Channel + 1;
		
		switch(Band)
		{
		case BAND_EMEA:
			if(chan > 9)
				chan = 0;
			break;
			
		case BAND_US:
			if(chan > 27)
				chan = 23;
			break;
			
		case BAND_EMEA_US:
			if(chan > 27)
			{
				chan = 0;
				break;
			}
			if( ( chan > 9 ) && ( chan < 23 ) )
			{
				chan = 23;
				break;
			}
			break;
			
		default:
			LOG("ERROR: Falschen Kanal angegeben");
			return false;
		}
		
		//LOG("Channelhop ...");
		return setChannel(chan);
	}
	
	/*
	 * Die Hilfsfunktion setMode setzt dem aktiviertem Device per ioctl die
	 * übergeben Kommando setState mit dem in param definierten Parameter.
	 * Gibt true bei erfolgreichem setzen des Modus zurück.
	 */
	private bool setMode(uint setState, ushort param)
	{
		if(ActiveState != setState)
		{
			if(sendIoctl(COA_IOCTL_MODE, param))
			{
				ActiveState = setState;
				return true;
			}
			LOG("ERROR: Konnte Modus nicht setzen {}",setState);
			return false;
		}
		return true;
	}
	
	/*
	 * Die Funktion setCallscanMode setzt den Callscanmode des Device.
	 * Gibt true bei erfolgreichem Setzen zurück.
	 */
	bool setCallscanMode()
	{
		LOG("Setze Callscan mode: asynchrones ScanPP");
		return setMode(MODE_CALLSCAN, COA_MODE_SNIFF | COA_SUBMODE_SNIFF_SCANPP);
	}

	/*
	 * Die Funktion setFpscanMode setzt den Fpscanmode des Device.
	 * Gibt true bei erfolgreichem Setzen zurück.
	 */
	bool setFpscanMode()
	{
		LOG("Setze Fpscan mode: asynchrones ScanFP");
		return setMode(MODE_FPSCAN, COA_MODE_SNIFF | COA_SUBMODE_SNIFF_SCANFP);
	}

	/*
	 * Die Funktion setPpscanMode setzt den Ppscanmode des Device und übermittelt
	 * die in RFPI angegebenen Parameter an die Karte.
	 * Gibt true bei erfolgreichem Setzen zurück.
	 */
	bool setPpscanMode(ubyte[] RFPI)
	{
		LOG("Setze Ppscan Mode: synchron");
		
		if(setMode(MODE_PPSCAN, COA_MODE_SNIFF | COA_SUBMODE_SNIFF_SYNC))
		{
			LOG("Setze RFPI: {0:X}", RFPI);
			return sendIoctl(COA_IOCTL_SETRFPI, RFPI);
		}
			
		LOG("ERROR: Konnte den PPSCAN mode nicht setzen");
		return false;
	}
	
	/*
	 * Die Funktion Fpscan führt einen FPscan (suche nach Basisstationen) oder einen
	 * Callscan (suche nach aktiven Handset Geräten) bei aktiviertem callscan parameter auf
	 * dem aktuellen Carrier aus.
	 * 
	 * Gibt ein assoziatives Array (mit der RFPI als key) aus Station-Objekten zurück. 
	 */
	Station[ubyte[]] Fpscan(bool callscan = false)
	{		
		if(callscan)
		{
			if(ActiveState != MODE_CALLSCAN)
			{
				LOG("Callscan gestartet");
				setCallscanMode();
			}
		}
		else
		{
			if(ActiveState != MODE_FPSCAN)
			{
				LOG("Fpscan gestartet");
				setFpscanMode();
			}
		}
		
		ubyte buf[7];
		Station[ubyte[]] sta;
		int read = 0;
		
		if(isReadDataWaiting())
		{
			while (7 == (read = oldRead(buf.ptr, 7)))
			{
				//LOG("Station gefunden...");
				auto tempRFPI = buf[2..7].dup;
				sta[tempRFPI] = createStation(buf[0..7].dup);
				if(callscan)
				{
					sta[tempRFPI].Type = TYPE_PP;
				}
				else
					sta[tempRFPI].Type = TYPE_FP;
				
			}
			
			if(read > 0)
			{
				LOG("WARNUNG: unvollstaendiges Paketgroesse! Erwartert: 7  Bekommen: {}", read);
			}
			
		}
		//LOG("bytes gelesen: {}",read);
		//LOG("Stationanzahl {}",sta.length);
		return sta;
	}

	/*
	 * Referenz auf Fpscan(true);
	 */
	Station[ubyte[]] Callscan()
	{
		return Fpscan(true);
	}
	
	/*
	 * Die Funktion PpscanSync setzt das Device in den PPscan sollte das noch nicht der Fall sein.
	 * Dann versucht das Device selbstständig sich mit der Verbindung zwischen PP und FP zu synchronisieren.
	 * Im Falle einer Synchronisation wird automatisch ein PcapObject erzeugt.
	 * 
	 */
	bool Ppscan(ubyte[] RFPI)
	{
			
		if(ActiveState != MODE_PPSCAN)
		{
			
			LOG("PPSCAN gestartet");
			
			if(RFPI.length != 5)
			{
				LOG("ERROR: Fehlerhafte RFPI");
				return false;
			}
			
			LOG("Versuche mit {0:X} auf Carrier {} zu synchronisieren", RFPI, Channel);
		
			if(!setPpscanMode(RFPI))
				return false;
			
			setChannel(this.Channel);
			
		}
		
		int read = 0;
		ulong total = 0;
		
		if(isReadDataWaiting())
		{
			//LOG("INFO: Daten zum Aufzeichnen gefunden");
			
			while (Packet.sizeof == (read = oldRead(&Packet, Packet.sizeof)))
			{	
				total += read;
				
				if (Pcap is null)
				{
					LOG("Synchronisation hergestellt");
					char[] Filename = Stdout.layout.convert("{0:x}{1:x}{2:x}{3:x}{4:x}-{5}",RFPI[0],RFPI[1],RFPI[2],RFPI[3],RFPI[4],time(null));
					this.Pcap = new PcapObject(Filename);
				}
				
				//LOG("INFO: Schreibe in PCAP");
				
				Pcap.addPacket(Packet);
				
				/* TEEEEEEEEEEEESSSSSSSSSST*/
				if(Packet.channel != this.Channel)
				{
					//LOG("WARNUNG: die Übertragung Verwendet einen anderen Carrier! Erwartet: {} Bekommen: {}", this.Channel, Packet.channel);
					this.Channel = Packet.channel;
				}
					
			}
			
			if(read > 0)
			{
				LOG("WARNUNG: unvollstaendiges Paket! Erwartet: {}  Bekommen: {}", Packet.sizeof ,read);
			}
			
			return true;
		}
		//LOG("INFO: Keine Daten gefunden");
		
		return false;
	}
	
	bool Ppscan(Station sta)
	{
		if((&sta) !is null)
		{
			this.Channel = sta.Channel;
			return Ppscan(sta.RFPI);
		}
		
		return false;
	}
		
	void autorec(ubyte[] RFPI = null)
	{
		time_t lasttime = 0; 
		time_t timeout = 10; // wie lang soll auf Daten gewertet werden
		Station sta;	// die gefundene Zielstation
		bool found = false; // eine Station gefunden?
		bool callscan = true;
		
		if(RFPI.length == 5)
			callscan = false;
		
		setStopMode(); // Definierter Startzustand IDLE
		
		while(!found)
		{			
			
			foreach(station; Fpscan(callscan))
			{
				if(!callscan)
				{
					if(station.RFPI == RFPI)
					{
						sta = station;
						found = true;
						LOG("Station gefunden mit der RFPI: {0:x} auf Carrier {1}",station.RFPI, station.Channel);
					}
				}
				else
				{
					sta = station;
					LOG("Anruf gefunden von der RFPI: {0:x} auf Carrier {1}",station.RFPI, station.Channel);
					found = true;
				}
				
			}
			if(!found)
				Channelhop();
			
		}
		
		lasttime = time(null); // Startzeit
		
		while(time(null) < (lasttime + timeout)) // solang kein timeout
		{
			while(Ppscan(sta)) // scan nach daten
			{
				
				//if(hasBField()) // sind Daten übertragen wurden
					lasttime = time(null); // Zeit an dem Daten empfangen wurden
								
			}
		}
		
		LOG("Synchronisation fehlgeschlagen...");
		stopPcap(); // stoppen der Aufzeichnung
	}
	
	void closeDevice()
	{
		LOG("Schliesse Device");
		setStopMode();
		close();
	}
	
	void stopPcap()
	{
		if(Pcap !is null)
		{
			Pcap.stopPcap();
			Pcap = null;
		}
	}
}