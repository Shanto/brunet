/*
Copyright (C) 2008  David Wolinsky <davidiw@ufl.edu>, University of Florida
                    Pierre St Juste <ptony82@ufl.edu>, University of Florida

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

using Brunet;
using Brunet.Applications;
using Brunet.Util;
using NetworkPackets;
using System;
using System.Collections;
using System.Net;
using System.Threading;

/**
\namespace Ipop::Managed
\brief Defines Ipop.Managed provide the ability to set up translation tables via Managed
*/
namespace Ipop.Managed {
  /// <summary>
  /// This class is a subclass of IpopNode
  /// </summary>
  public class ManagedIpopNode: IpopNode {
    /// <summary>Provides Address resolution, dns, and translation.</summary>
    protected ManagedAddressResolverAndDns _marad;

    /// <summary>
    /// The constructor takes two config files
    /// </summary>
    /// <param name="NodeConfigPath">Node config object</param>
    /// <param name="IpopConfigPath">Ipop config object</param>
    public ManagedIpopNode(NodeConfig node_config, IpopConfig ipop_config) :
      base(node_config, ipop_config, null)
    {
      _dhcp_server = ManagedDhcpServer.GetManagedDhcpServer(_ipop_config.VirtualNetworkDevice);  
      _dhcp_config = _dhcp_server.Config;
      _marad = new ManagedAddressResolverAndDns(AppNode.Node, _dhcp_server,
          ((ManagedDhcpServer) _dhcp_server).LocalIP, _ipop_config.Dns.NameServer,
          _ipop_config.Dns.ForwardQueries);
      _dns = _marad;
      _address_resolver = _marad;
      _translator = _marad;
    }

    protected override DhcpServer GetDhcpServer() {
      return _dhcp_server;
    }

    protected override void GetDhcpConfig() {
    }

    /// <summary>
    /// This method handles incoming Dns Packets
    /// </summary>
    /// <param name="ipp">A Dns IPPacket to be processed</param>
    /// <returns>A boolean result</returns>
    protected override bool HandleDns(IPPacket ipp) {
      WriteIP(_dns.LookUp(ipp).ICPacket);
      return true;
    }

    /// <summary>
    /// This method handles multicast packets (not yet implemented)
    /// </summary>
    /// <param name="ipp">A multicast packet to be processed</param>
    /// <returns></returns>
    protected override bool HandleMulticast(IPPacket ipp) {
      foreach(Address addr in _marad.mcast_addr) {
        SendIP(addr, ipp.Packet);
      }
      return true;
    }
  }
}
