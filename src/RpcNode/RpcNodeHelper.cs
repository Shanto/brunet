/*
Copyright (C) 2008  Pierre St Juste <ptony82@ufl.edu>, University of Florida
                    David Wolinsky <davidiw@ufl.edu>, University of Florida

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

using Brunet.Applications;
using Ipop;
using System;
using System.Collections;

namespace Ipop.RpcNode
{
    public class RpcNodeHelper
    {
        /// <summary> 
        /// Finds an available on the system 
        /// <param name="networkdevice">Device to be ignored</param> 
        /// <param name="startip">Device to be ignored</param> 
        /// <returns>Return IP to use</returns> 
        /// </summary>
        public static string GetNetwork(string networkdevice, string startip)
        { 
            IPAddresses ipaddrs = IPAddresses.GetIPAddresses();
            ArrayList used_networks = new ArrayList();
            byte[] netip = Utils.StringToBytes(startip, '.');

            foreach (Hashtable ht in ipaddrs.AllInterfaces)
            {
                if (ht["inet addr"] != null && ht["Mask"] != null 
                    && (string)ht["interface"] != networkdevice)
                {
                    byte[] addr = Utils.StringToBytes((string)ht["inet addr"], '.');
                    byte[] mask = Utils.StringToBytes((string)ht["Mask"], '.');

                    for (int i = 0; i < addr.Length; i++)
                    {
                        addr[i] = (byte)(addr[i] & mask[i]);
                    }

                    used_networks.Add(addr);
                }
            }

            while (true)
            {
                if (!used_networks.Contains(netip))
                {
                    break;
                }
                if (netip[1] == 0)
                {
                    Console.WriteLine("No usable networks found");
                    return null;
                }
                netip[1] -= 1;
            }

            return Utils.BytesToString(netip, '.');
        }

        /// <summary> 
        /// A config object that is available for the system
        /// <param name="networkdevice">Device to be ignored</param> 
        /// <returns>Return IP to use</returns> 
        /// </summary>
        public static DHCPServerConfig GenerateDHCPServerConfig(String IP, String Netmask)
        {
            DHCPServerConfig config = new DHCPServerConfig();
            config.leasetime = 3200;
            config.netmask = Netmask;
            config.pool = new DHCPServerConfig.IPPool();
            config.pool.lower = IP;

            byte[] ipb = Utils.StringToBytes(IP, '.');
            byte[] netmask = Utils.StringToBytes(Netmask, '.');
            for(int i = 0; i < 4; i++) {
              ipb[i] += (byte) ~netmask[i];
            }
            config.pool.upper = Utils.BytesToString(ipb, '.');
            return config;
        }

    }
}