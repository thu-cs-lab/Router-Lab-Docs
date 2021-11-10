# 维基百科

考虑到部分同学访问英文维基百科可能有一些困难，这里把实验会访问的一些页面的部分截图放在这里，以供大家参考。

这一部分内容的许可证与维基百科一致：Creative Commons Attribution-ShareAlike

## IPv6 Header

[原网页](https://en.wikipedia.org/wiki/IPv6_packet)

![](img/ipv6_header.png)

- Version (4 bits)

The constant 6 (bit sequence 0110).

- Traffic Class (6+2 bits)

The bits of this field hold two values. The six most-significant bits hold the differentiated services field (DS field), which is used to classify packets.[2][3] Currently, all standard DS fields end with a '0' bit. Any DS field that ends with two '1' bits is intended for local or experimental use.[4]
The remaining two bits are used for Explicit Congestion Notification (ECN);[5] priority values subdivide into ranges: traffic where the source provides congestion control and non-congestion control traffic.

- Flow Label (20 bits)

A high-entropy identifier of a flow of packets between a source and destination. A flow is a group of packets, e.g., a TCP session or a media stream. The special flow label 0 means the packet does not belong to any flow (using this scheme). An older scheme identifies flow by source address and port, destination address and port, protocol (value of the last Next Header field).[6] It has further been suggested that the flow label be used to help detect spoofed packets.[7]

- Payload Length (16 bits)

The size of the payload in octets, including any extension headers. The length is set to zero when a Hop-by-Hop extension header carries a Jumbo Payload option.[8]

- Next Header (8 bits)

Specifies the type of the next header. This field usually specifies the transport layer protocol used by a packet's payload. When extension headers are present in the packet this field indicates which extension header follows. The values are shared with those used for the IPv4 protocol field, as both fields have the same function (see List of IP protocol numbers).

- Hop Limit (8 bits)

Replaces the time to live field in IPv4. This value is decremented by one at each forwarding node and the packet is discarded if it becomes 0. However, the destination node should process the packet normally even if received with a hop limit of 0.

- Source Address (128 bits)

The unicast IPv6 address of the sending node.

- Destination Address (128 bits)

The IPv6 unicast or multicast address of the destination node(s).
In order to increase performance, and since current link layer technology and transport layer protocols are assumed to provide sufficient error detection,[9] the header has no checksum to protect it.[1]