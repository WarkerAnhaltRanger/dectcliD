module MyDevice;

//import tango.io.device.DeviceConduit;
import tango.io.device.Device;
import tango.sys.linux.linux;
alias tango.sys.linux.linux Posix;

debug
{
	import tango.io.Stdout;
}

extern(C)
{
	int ioctl(int fd, uint cmd, ...);
}

class MyDevice : Device/*Conduit*/
{
	
	private char[] DevicePath;
	private fd_set rfd/*, wfd, efd*/; 
	private uint milliseconds;
	private timeval tv;
	
	this(char[] DevicePath, uint milliseconds = 1000)
	{
		this.DevicePath = DevicePath;
		this.milliseconds = milliseconds;
	}
	
	void initSets()
	{
		Posix.FD_ZERO(&rfd);
		//Posix.FD_ZERO(&wfd);
		//Posix.FD_ZERO(&efd);
		Posix.FD_SET(handle, &rfd);
		//FD_SET(handle, &efd);
	}
		
	int open(int Options)
	{
		
		debug
		{
			Stdout.formatln("öffne Device");
		}
		if((handle = Posix.open(this.DevicePath.ptr, Options)) < 0)
				error("Konnte Device nicht öffnen\n");
		
		debug
		{
			Stdout.formatln("Device Filedescriptor: {}",handle);
		}
		
		return handle;
	}
	
	private int waitSelector(uint milliseconds)
	{	
		initSets();
				
		tv.tv_sec = milliseconds / 1000;
		tv.tv_usec = ( milliseconds - (tv.tv_sec * 1000) ) * 1000;
		return Posix.select(handle + 1, &rfd, null/*&wfd*/, null/*&efd*/, &tv);
	}
	
	private bool isDataWaiting(fd_set Set)
	{
		
		if(waitSelector(milliseconds) < 0)
		{
			debug
			{
				Stdout.formatln("Da lief was mit select falsch");
			}
		}
		
		if(Posix.FD_ISSET(handle, &Set))
		{
			debug
			{
				Stdout.formatln(" Daten Warten");
			}
			return true;
		}
		debug
		{
			Stdout.formatln(" Keine Daten");
		}
		return false;
	}
	
	bool isReadDataWaiting()
	{
		return isDataWaiting(rfd);
	}
	
	bool sendIoctl(uint cmd, ushort params)
	{
		debug
		{
			Stdout.formatln("IOCTL mit {0:x} {1:x}", cmd, params);
		}
		
		if(ioctl(handle, cmd, &params))
		{
			error("IOCTL hat einen fehler gemeldet\n");
			debug
			{
				Stdout.formatln("Fehler in ioctl mit {0:x} {1:x}", cmd, params);
			}
			return false;
		}
		return true;
	}
	
	bool sendIoctl(uint cmd, ubyte[] params)
	{
		debug
		{
			Stdout.formatln("IOCTL mit {0:x} {1:x}", cmd, params);
		}
		
		if(ioctl(handle, cmd, params.ptr))
		{
			debug
			{
				Stdout.formatln("Fehler in ioctl mit {0:x} {1:x}", cmd, params);
			}
			error("IOCTL hat einen fehler gemeldet\n");
			return false;
		}
		return true;
	}
	
	override bool isAlive()
	{
		if(handle > 0)
			return true;
		
		return false;
	}
	
	int oldRead(void* buf, size_t len)
	{
		return Posix.read(handle, buf, len);
	}
	
}