module DectDeviceStructs;

enum : ushort
{
	COA_MODE_IDLE   			= 0x0000,
	COA_SUBMODE_SNIFF_SCANFP	= 0x0001,
	COA_SUBMODE_SNIFF_SCANPP	= 0x0002,
	COA_SUBMODE_SNIFF_SYNC		= 0x0003,	
	COA_SUBMODEMASK				= 0x00FF,
	COA_MODE_FP     			= 0x0100,
	COA_MODE_PP     			= 0x0200,
	COA_MODE_SNIFF  			= 0x0300,
	COA_MODE_JAM    			= 0x0400,
	COA_MODE_EEPROM 			= 0x0500,
	COA_IOCTL_MODE				= 0xD000,
	COA_IOCTL_RADIO				= 0xD001,
	COA_IOCTL_RX				= 0xD002,
	COA_IOCTL_TX				= 0xD003,
	COA_IOCTL_CHAN				= 0xD004,
	COA_IOCTL_SLOT				= 0xD005,
	COA_IOCTL_RSSI				= 0xD006,
	COA_IOCTL_FIRMWARE			= 0xD007, /* request_firmware() */
	COA_IOCTL_SETRFPI			= 0xD008,
	COA_MODEMASK 				= 0xFF00
}

enum
{
	MODE_STOP     = 0x00000001,
	MODE_FPSCAN   = 0x00000002,
	MODE_PPSCAN   = 0x00000004,
	MODE_CALLSCAN = 0x00000008,
	MODE_JAM      = 0x00000010
}

enum : ubyte
{
	BAND_EMEA 		= 0x01,
	BAND_US	  		= 0x02,
	BAND_EMEA_US	= 0x03
}

enum : ubyte
{
	TYPE_FP = 0x01,
	TYPE_PP = 0x02
}

struct Station
{
	ubyte[5] 	RFPI;
	ubyte 		Channel;
	ubyte 		RSSI;	
	ubyte		Type;
}
