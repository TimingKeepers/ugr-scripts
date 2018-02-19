/****************************
 * NAME: dummy_sender.c
 *
 * DESCRIPTION:
 *  tool to send periodical custom raw ethernet frames from a
 *  configurable network interface. Tested on WR Switch.
 * 
 * USAGE:
 *  dummy_sender -i interface [-d destination MAC addr]
 *                            [-s source MAC addr]
 *                            [-t Ethertype]
 *                            [-c number of packets]
 *                            [-p period (in us)]
 *
 * AUTHOR:
 *  Jose Lopez-Jimenez <joselj at ugr.es>
 *
 * DATES:
 *  Creation: 2018-02-13
 *  Last updated: 2018-02-15
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>
#include <unistd.h>
#include <ctype.h>

#define DEFAULT_IF      "lo"
#define BUF_SIZ         1024 

uint16_t checksum(const uint16_t* buf, unsigned int nbytes)
{
    uint32_t sum = 0;
    for(;nbytes>1;nbytes-=2)
    {
        sum += *buf++;
    }

    if(nbytes == 1)
    {
        sum += *(unsigned char*) buf;
    }

    sum = (sum >> 16) + (sum & 0xFFFF);
    sum += (sum >> 16);

    return ~sum;
}

void print_help(){
    printf("Usage:\n");
    printf("dummy_sender -i interface [-d dst_mac] [-s src_mac] [-t ethertype]\n");
    printf("                          [-c count] [-p period (us)]\n");
    printf("Example:\n\t dummy_sender -i wr1 -d 01:19:1B:00:00:00 -t 0x88F7");
    
    exit(0);
}

int main(int argc, char *argv[])
{
    int sockfd;
    struct ifreq if_idx;
    struct ifreq if_mac;
    int tx_len = 0;
    char sendbuf[BUF_SIZ];
    char s_addr[INET_ADDRSTRLEN];
    char d_addr[INET_ADDRSTRLEN];
    int c,j;
    int count=0;
    int values[6];
    int period = 200000;

    struct ether_header *eh = (struct ether_header *) sendbuf;
    struct iphdr *iph = (struct iphdr *) (sendbuf + sizeof(struct ether_header));
    struct udphdr *udph = (struct udphdr *) (sendbuf + sizeof(struct ether_header) + sizeof(struct iphdr));

    struct sockaddr_ll socket_address;
    char ifName[IFNAMSIZ];
    uint8_t dst_mac[6]={0x01,0x1b,0x19,0x00,0x00,0x00}; // Default is raw ethernet PTP.
    uint8_t src_mac[6];
    long eth_type=0;
    char ** endstr = NULL;
    int user_srcadr = 0;
    strcpy(s_addr,"127.0.0.1"); // Does not really matter
    strcpy(d_addr,"127.0.0.1"); // for a switch.
    struct in_addr saddr_b,daddr_b;
    
    strcpy(ifName, DEFAULT_IF);

    while((c=getopt(argc,argv,"i:d:s:t:hc:p:")) != -1)
        switch(c)
        {
            case 'i': // Network interface
                strcpy(ifName,optarg);
                break;
            case 'd': // Destination MAC address
                if( 6 == sscanf( optarg, "%x:%x:%x:%x:%x:%x%*c", &values[0], &values[1], &values[2], &values[3], &values[4], &values[5])){
                    for(j=0;j<6;++j)
                        dst_mac[j] = (uint8_t) values[j];
                }else{
                    fprintf(stderr,"Error parsing src MAC.\nMAC addr format must be XX:XX:XX:XX:XX:XX\n");
                    print_help();
                }
                break;
            case 't': // Ethertype
                eth_type = strtol(optarg,endstr,16);
                break;
            case 's': // Source addr
                if( 6 == sscanf( optarg, "%x:%x:%x:%x:%x:%x%*c", &values[0], &values[1], &values[2], &values[3], &values[4], &values[5])){
                    for(j=0;j<6;++j)
                        src_mac[j] = (uint8_t) values[j];
                    user_srcadr = 1;
                }else{
                    fprintf(stderr,"Error parsing src MAC.\nMAC addr format must be XX:XX:XX:XX:XX:XX\n");
                    print_help();
                }
                break;
            
            case 'h':
                print_help();
                break;

            case 'c':
                count=atoi(optarg);
                break;

            case 'p':
                period=atoi(optarg);
                break;

            case '?':
                if(optopt == 'i' || optopt == 'd' || optopt == 't')
                {
                    fprintf(stderr,"Option -%c requires an interface name.\n",optopt);
                    exit(0);
                }
                else if(optopt == 'd')
                {
                    fprintf(stderr, "Option -%c requires a MAC address XX:XX:XX:XX:XX:XX.\n",optopt);
                    exit(0);
                }
                else if(optopt == 't')
                {
                    fprintf(stderr, "Option -%c requires an ethertype from 0000 to FFFF.\n",optopt);
                    exit(0);
                }
                else if(isprint(optopt))
                {
                    fprintf(stderr,"Unknown option '-%c'.\n",optopt);
                    print_help();
                }
                else
                {
                    fprintf(stderr,"Unknown option character '\\x%x'.\n",optopt);
                    print_help();
                }

        }


    if((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1){
        perror("socket");
    }

    // Getting network interface from name:
    memset(&if_idx,0,sizeof(struct ifreq));
    strncpy(if_idx.ifr_name,ifName,IFNAMSIZ-1);
    if(ioctl(sockfd,SIOCGIFINDEX,&if_idx)<0)
        perror("SIOCGIFINDEX");

    // Getting source mac address from network interface:
    memset(&if_mac,0,sizeof(struct ifreq));
    strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
    if(ioctl(sockfd, SIOCGIFHWADDR, &if_mac)<0)
        perror("SIOCGIFHWADDR");

    // Make sure that the buffer is clear
    memset(sendbuf,0,BUF_SIZ);

    // Fill ethernet header with actual or user-defined source MAC address
    if(user_srcadr == 1){
        for(j=0;j<6;j++) eh->ether_shost[j] = src_mac[j];
    }
    else{
        for(j=0;j<6;j++) eh->ether_shost[j] = ((uint8_t *) &if_mac.ifr_hwaddr.sa_data)[j];
    }

    // Same for dest MAC address
    for(j=0;j<6;j++) eh->ether_dhost[j] = dst_mac[j];

    // And same for Ethertype
    if(eth_type != 0){
        eh->ether_type = htons((uint16_t) eth_type);
    }else{
        eh->ether_type = htons(ETH_P_IP);
    }

    // We are done with the Ethernet header and now it is turn for the IP header.
    // First some fields of no real importance for our purposes.
    iph->ihl     = 5;
    iph->ttl     = 64;
    iph->version = 4;
    iph->protocol= IPPROTO_RAW;
    
    // The strings containing IP addresses are parsed
    // and stored in another variable
    inet_aton(s_addr,&saddr_b);
    inet_aton(d_addr,&daddr_b);

    // Because of endianness issues, the IP addresses are written into
    // the buffer byte upon byte, so we make use of some auxiliary
    // pointers.
    uint8_t * tmp_ptr1 = (uint8_t *) &iph->saddr;
    uint8_t * tmp_ptr2 = (uint8_t *) &saddr_b;
    uint8_t * tmp_ptr3 = (uint8_t *) &daddr_b;


    for(j=0;j<4;j++){
        *(tmp_ptr1+j) = *(tmp_ptr2+j); 
    }

    tmp_ptr1 = (uint8_t *) &iph->daddr;

    for(j=0;j<4;j++){
        *(tmp_ptr1+j) = *(tmp_ptr3+j); 
    }

    // Testing that every part of the address is in its place
    /*
    tmp_ptr1 = (uint8_t *) &iph->saddr;
    for(j=-2;j<11;j++){
        
        printf("Addr: %p content: %x\n",(tmp_ptr1+j),*(tmp_ptr1+j));

    }
    */
    
    // IP header checksum
    iph->check   = htons(checksum((unsigned short *) iph, sizeof(struct iphdr)));

    // No need for UDP things, so instead we just write a bunch of bytes so that
    // the frames are not empty.
    udph->source = htons(1797);
    udph->dest   = htons(1798);

    tx_len += sizeof(struct ether_header) + sizeof(struct iphdr) + sizeof(struct udphdr);

    tx_len += 32;
    sendbuf[tx_len++] = 0x01;
    sendbuf[tx_len++] = 0x02;
    sendbuf[tx_len++] = 0x03;
    sendbuf[tx_len++] = 0x04;
    sendbuf[tx_len++] = 0x05;
    sendbuf[tx_len++] = 0x06;
    sendbuf[tx_len++] = 0x07;
    sendbuf[tx_len++] = 0x08;
    sendbuf[tx_len++] = 0x09;
    sendbuf[tx_len++] = 0x0a;
    sendbuf[tx_len++] = 0xde;
    sendbuf[tx_len++] = 0xad;
    sendbuf[tx_len++] = 0xbe;
    sendbuf[tx_len++] = 0xef;

    socket_address.sll_ifindex = if_idx.ifr_ifindex;
    socket_address.sll_halen = ETH_ALEN;

    socket_address.sll_addr[0] = dst_mac[0];
    socket_address.sll_addr[0] = dst_mac[1];
    socket_address.sll_addr[0] = dst_mac[2];
    socket_address.sll_addr[0] = dst_mac[3];
    socket_address.sll_addr[0] = dst_mac[4];
    socket_address.sll_addr[0] = dst_mac[5];

    iph->tot_len = htons(tx_len);
    udph->len    = htons(tx_len - sizeof(struct ether_header) - sizeof(struct iphdr));

    // Rinse and repeat
    if(count==0)
    {
        for(;;){
            if(sendto(sockfd,sendbuf,tx_len,0,(struct sockaddr*)&socket_address,sizeof(struct sockaddr_ll))<0)
                printf("Failure sending frame\n");

            usleep(200000);

        }
    }else{
        while(count-- > 0)
        {

            if(sendto(sockfd,sendbuf,tx_len,0,(struct sockaddr*)&socket_address,sizeof(struct sockaddr_ll))<0)
                printf("Failure sending frame\n");

            usleep(period);
        }
    }

    return 0;

}


