/****************************
 * NAME: spll_reader.c
 *
 * DESCRIPTION:
 *  tool to remotely extract data from softpll debug registers and
 *  provide addequate format.
 * 
 * NOTES:
 *  -   "spll_proxy_debug" has to be run in the WR device. 12345 is the
 *      default port of the server side.
 *  -   Based on http://www.cs.rpi.edu/~moorthy/Courses/os98/Pgms/socket.html
 *      example by Mukkai S. Krishnamoorthy for a basic blocking
 *      network socket.
 *
 * AUTHOR:
 *  Jose Lopez-Jimenez <joselj at ugr.es>
 *
 * DATES:
 *  Creation: 2018-01-22
 *  Last updated: 2018-02-08
 */


#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <ctype.h>

// Conversion to binary as suggested in
// https://stackoverflow.com/questions/111928/is-there-a-printf-converter-to-print-in-binary-format
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
      (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

#define DBG_Y 0
#define DBG_ERR 1
#define DBG_TAG 2
#define DBG_REF 5
#define DBG_PERIOD 3
#define DBG_EVENT 4
#define DBG_SAMPLE_ID 6

#define DBG_HELPER 0x20         /* Sample source: Helper PLL */
#define DBG_EXT 0x40            /* Sample source: External Reference PLL */
#define DBG_MAIN 0x0            /* ...          : Main PLL */

#define DBG_EVT_START 1         /* PLL has just started */
#define DBG_EVT_LOCKED 2        /* PLL has just become locked */

#define MODE_BINARY 0x1
#define MODE_STDOUT 0x2
#define MODE_FILE 0x4
#define MODE_CSV 0x8
#define MODE_HEADER 0x100

#define LINE_WIDTH 64 
#define FEEDBACK_PERIOD 48


void error(char *msg)
{
    perror(msg);
    exit(0);
}

void printHelp(char *name){
    printf("Usage: %s -a addr -p port [-b] [-v] [-m] [-e] [-f filename]\n",name);
    printf("\t-a IP address of the server\n");
    printf("\t-p Port\n");
    printf("\t-b Binary mode, only with files.\n");
    printf("\t-v Display incoming data.\n");
    printf("\t-m Save data in csv file for Matlab/Octave/... further processing.\n");
    printf("\t-e Include descripting header in csv file\n");
    printf("\t-f Prefix for target files of debug data.\n");
    exit(0);
}

/* FIXME: this should close the file descriptors properly*/
void sigintHandler(int sig_num){
    exit(0);
}


int parse_spll_sample(FILE ** fds, char *dst, uint32_t value, uint16_t seq_id, uint32_t options){

    char temp[2048];


    // Bit-parsing data from SPLL debug fifo
    uint32_t source = 0x6 & (value>>28);
    uint32_t type = 0xF & (value>>24);
    uint32_t sample_value = 0xFFFFFF & value;

    
    if((options & MODE_CSV))
    {
        sprintf(dst,"%05d,%d,%d\n",seq_id,source,sample_value);
        fprintf(fds[type],"%s",dst);
    }
    else
    {   // Formatting data in a table manner.
        strcpy(dst," ID ");
        sprintf(temp,"%05d",seq_id);
        strcat(dst,temp);
        strcat(dst," | RAW:");
        sprintf(temp,"0x%08X | ",value);
        strcat(dst,temp);
        switch(source){
            case 4:
                strcat(dst,"ePLL [0x");
                break;
            case 2:
                strcat(dst,"hPLL [0x");
                break;
            case 0:
                strcat(dst,"mPLL [0x");
                break;
            default:
                strcat(dst,"UKNWN: [0x"); //unknown data source
        }

        sprintf(temp,"%d] ",source);
        strcat(dst,temp);

        switch(type){
            case 0 :
                strcat(dst,"| Y  \t    : [0x");
                break;
            case 1 :
                strcat(dst,"| ERROR\t    : [0x");
                break;
            case 2 :
                strcat(dst,"| TAG LOCAL : [0x");
                break;
            case 3 :
                strcat(dst,"| PERIOD \t  : [0x");
                break;
            case 4 :
                strcat(dst,"| EVENT \t  : [0x");
                break;
            case 5 :
                strcat(dst,"| TAG REF   : [0x");
                break;
            case 6 :
                strcat(dst,"| SAMPLE ID : [0x");
                break;
            default :
                strcat(dst,"| UNKNOWN! : [0x");
        }

        sprintf(temp,"%x] |  ",type);
        strcat(dst,temp);
        strcat(dst,"");


        sprintf(temp,"%d\n",(int32_t) (sample_value % 0xFFFFFF));
        strcat(dst,temp);

        if( (0x80000000 & value) )
            strcat(dst,"--------------------------------------------------------------------------------\n");
        fprintf(fds[0],"%s",dst);
    }
/* TODO: EVENTS (START, LOCKED) ARE IGNORED!!!*/             
    return 0;
}



int main(int argc, char *argv[])
{
    int sockfd, portno;

    uint32_t options = 0;
    char filename[32];

    int index, c;
    long update_counter = 0.0;

    struct sockaddr_in serv_addr;
    struct hostent *server;

    char buffer[2048];
    char tempSample[1024];

    FILE *fpointers[7];
    char filenames[7][32];

    opterr=0;


    while ((c=getopt(argc,argv,"ha:p:bmevf:")) != -1)
        switch(c)
        {
            case 'h':
                printHelp(argv[0]);
                break;
            case 'm':
                options |= MODE_CSV;
                break;
            case 'e':
                options |= MODE_HEADER;
                break;
            case 'a':
                server=gethostbyname(optarg);
                break;
            case 'p':
                portno=atoi(optarg);
                break;
            case 'b':
                printf("Binary mode is not yet implemented. Sorry!\n");
                exit(0);
                options |= MODE_BINARY;
                break;
            case 'f':
                options |= MODE_FILE;
                options = options | (!MODE_STDOUT);
                strcpy(filename,optarg);
                break;
            case 'v':
                options = options | MODE_STDOUT;
                break;
            case '?':
                if (optopt == 'f')
                {
                    fprintf(stderr,"Option -%c requires a file name.\n", optopt);
                }
                else if (isprint (optopt) )
                {
                    fprintf(stderr,"Unknown option '-%c'.\n", optopt);
                    printHelp(argv[0]);
                }
                else{
                    fprintf(stderr,"Unknown option character '\\x%x'.\n",optopt);
                    printHelp(argv[0]);
                }
                return 1;
            default:
                abort();
        }

    printf("Mode binary = %d\nMode printout = %d\nMode file = %d\nMode csv =\
 %d\n",((options & MODE_BINARY) != 0), ((options & MODE_STDOUT) != 0), ((options & MODE_FILE) != 0), ((options & MODE_CSV) != 0));

    for (index = optind; index < argc; index++)
    {
        printf( "Non-option argument %s\n", argv[index]);
        printHelp(argv[0]);
    }


    signal(SIGINT, sigintHandler);

    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) 
        error("ERROR opening socket");

    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host\n");
        exit(0);
    }

    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;

    bcopy((char *)server->h_addr, 
         (char *)&serv_addr.sin_addr.s_addr,
         server->h_length);
    serv_addr.sin_port = htons(portno);
    
    if (connect(sockfd,(struct sockaddr *)&serv_addr,sizeof(serv_addr)) < 0) 
        error("ERROR connecting");
    bzero(buffer,2048);

    if((options & MODE_CSV) && (options & MODE_FILE))
    {
        for(index=0;index<7;index++){
            strcpy(filenames[index],filename);
        }
        strcat(filenames[0],"_y");
        strcat(filenames[1],"_error");
        strcat(filenames[2],"_taglocal");
        strcat(filenames[3],"_period");
        strcat(filenames[4],"_event");
        strcat(filenames[5],"_tagref");
        strcat(filenames[6],"_sampleid");

//        for(index=0;index<7;index++)
//            printf("%s\n",filenames[index]);


        for(index=0;index<(sizeof(fpointers)/sizeof(fpointers[0]));index++){
            fpointers[index]=fopen(filenames[index],"w");
            if(fpointers[index]==NULL)
            {
                printf("Could not open file %s\n",filenames[index]);
                exit(-1);
            }
        }
    }else if(options & MODE_FILE & ~MODE_CSV)
    {
        fpointers[0] = fopen(filename,"w");
        if(fpointers[0]==NULL)
        {
            printf("Could not open file %s\n",filename);
            exit(-1);
        }
    }

    // Not very useful to print a header if now CSV mode separates
    // every variable in a different file, but still...
    if((options & MODE_CSV ) & (options & MODE_HEADER))
    {
        fprintf(fpointers[index],"seq_id,source,type,sample_value\n\
source:\t0 - main PLL\n\
\t2 - helper PLL\n\
\t4 - ext PLL\n");
        fprintf(fpointers[index],"type:\t0 - y\n\
\t1 - error\n\
\t2 - tag local\n\
\t3 - period\n\
\t4 - event\n\
\t5 - tag ref\n\
\t6 - sample id\n");
    }

    int fr_block = 0;
    int sample_count=0;

    uint16_t *shortp;
    uint16_t value_hi,value_lo,seq_id;

    for(;;)
    {
        update_counter++;
        if(!(update_counter%FEEDBACK_PERIOD))
        {
            printf("/");
            fflush(stdout);
        }

        if(!(update_counter % (LINE_WIDTH*FEEDBACK_PERIOD)))
        {
            printf("\n");
        }


        fr_block = recv(sockfd,buffer,sizeof(buffer),0);
        shortp = &buffer;
        
        while(fr_block>0){
            sample_count++;
            
            value_hi = shortp[1];
            value_lo = shortp[0];
            seq_id   = shortp[2];
            shortp  += 4;

            parse_spll_sample(fpointers,tempSample,( (value_hi<<16) | value_lo) ,seq_id,options);

            if((options & MODE_STDOUT))
                printf("%s",tempSample);
            
            fr_block -= 8;

        }
        bzero(buffer,2048);
        usleep(40);
    }
}
