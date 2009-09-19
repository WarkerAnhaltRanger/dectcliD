module PcapObject;

import PcapStructs;
import Integer = tango.text.convert.Integer;
import tango.stdc.time;
import tango.io.Stdout;

class PcapObject : Object
{
	
	private char[] Filename;
	private int* PcapDump;
	private pcap* Pcap;
	
	this(char[] filename)
	{
		this.Filename = filename ~ ".pcap";
		initPcap();
	}
	
	this()
	{
		this.Filename = Integer.toString(time(null)) ~ ".pcap";
		initPcap();
	}
	
	~this()
	{
		stopPcap();
	}
	
	private void initPcap()
	{
		this.Pcap = pcap_open_dead(1, 73);
		if(this.Pcap !is null)
		{
			this.PcapDump = pcap_dump_open(this.Pcap, this.Filename.ptr);
			if(this.PcapDump !is null)
				Stdout.formatln("Speichere Dump unter {}", this.Filename);
		}
	}
	
	public void stopPcap()
	{
		if(this.Pcap !is null)
		{
			pcap_dump_close(this.PcapDump);
			pcap_close(this.Pcap);
			this.PcapDump = null;
			this.Pcap = null;
		}
	}
	
	public bool addPacket(packet Packet)
	{
		if(this.Pcap !is null && this.PcapDump !is null)
		{
			PrintPacket(Packet);
			
			pcap_pkthdr pcap_hdr;
			pcap_hdr.ts.tv_sec = Packet.timestamp.tv_sec;
			pcap_hdr.ts.tv_usec = Packet.timestamp.tv_nsec / 1000;
			pcap_hdr.caplen = 73;
			pcap_hdr.len = 73;
			
			ubyte pcap_packet[100] = 0;
			pcap_packet[12] = 0x23;
			pcap_packet[13] = 0x23;
			pcap_packet[14] = 0x00;
			pcap_packet[15] = Packet.channel;
			pcap_packet[16] = 0x00;
			pcap_packet[17] = Packet.slot;
			pcap_packet[18] = Packet.frameflags & 0x0f;
			pcap_packet[19] = Packet.rssi;
			pcap_packet[20..73] = Packet.data[0..53];
			
			pcap_dump(this.PcapDump, &pcap_hdr, pcap_packet.ptr);
			return true;
		}
		return false;
	}
	
	public void PrintPacket(packet Packet)
	{
		// C-Kanal-Pakete sind in 5 Bytes Fraktmentiert
		if((&Packet) !is null)
		{
			if((Packet.data[5] & 0xc0) == 0)
			{
				ubyte len = Packet.data[8]>>2;
				
				if(len <= Packet.data.length)
				{
				
					if(Packet.data[3] == 0x16)
					{
						//telefon
						if(len > 6)
							Stdout.formatln("CChan-Daten: {0:x}", Packet.data[6..len]);
						
					}
					else if(Packet.data[3] == 0xe9)
					{
						//basisstation
					}
				}
			}
			//Stdout.formatln("Packet: Kanal: {0} Slot: {1} FrameFlags: {2:x} RSSI: {3} Data: {4:x}", Packet.channel, Packet.slot, Packet.frameflags & 0x0f, Packet.rssi, Packet.data);
		}
	}
	
}