module PcapStructs;

import tango.stdc.time;

extern(C)
{
	struct packet
	{
		ubyte rssi;
		ubyte channel;
		ubyte slot;
		ubyte frameflags; // bei Kismet DECT fehlt dieses Byte
		timespec   timestamp;
		ubyte data[53];
	}

	struct timespec
	{	
		time_t tv_sec;
		int tv_nsec;
	}

	struct timeval
	{
		time_t tv_sec;
		uint tv_usec;
	}

	struct pcap_pkthdr
	{
		timeval ts;
		uint caplen;
		uint len;
	}

	struct pcap;
	/*{
		int fd;
    	int selectable_fd;
    	int send_fd;
		int snapshot;
		int linktype;
		int tzoff;
		int offset;
		int break_loop;
	
		pcap_sf sf;
		pcap_md md;
	
		int fddipad;
		
		int bufsize;
    	ubyte *buffer;
    	ubyte *bp;
    	int cc;
		
		ubyte* pkt;
		
		int	(*read_op)(pcap *, int cnt, void(* pcap_handler)(ubyte *, pcap_pkthdr *, ubyte*) , ubyte *);
		int	(*setfilter_op)(pcap *, bpf_program *);
		int	(*set_datalink_op)(pcap *, int);
		int	(*getnonblock_op)(pcap *, char *);
		int	(*setnonblock_op)(pcap *, int, char *);
		int	(*stats_op)(pcap *, pcap_stat *);
		void (*close_op)(pcap *);

		bpf_program fcode;
		
		char errbuf[256];
		int dlt_count;
		int *dlt_list;

		pcap_pkthdr pcap_header;
	}*/
	
	
	/*struct bpf_program
	{
		uint bf_len;
		bpf_insn* bf_insns;
	}*/

	/*struct bpf_insn
	{
		ushort code;
		ubyte jt;
		ubyte jf;
		int k;
	}*/

	/*struct pcap_sf
	{
		int* rfile;
		int swapped;
		int hdrsize;
		int version_major;
		int version_minor;
		ubyte* base;
	}*/

	/*struct pcap_md
	{
		pcap_stat stat;
		int use_bpf;
		uint TotPkts;
		uint TotAccepted;
		uint TotDrops;
		int TotMissed;
		int OrigMissed;
	}*/
	
	/*struct pcap_stat
	{
		uint ps_recv;
		uint ps_drop;
		uint ps_ifdrop;
	}*/

	pcap* pcap_open_dead(int linktype, int snaplen);
	int* pcap_dump_open(pcap* p, char* fname);
	void pcap_dump_close(int* p);
	void pcap_close(pcap* p);
	void pcap_dump(int* user, pcap_pkthdr* h, ubyte* sp);
	
}
