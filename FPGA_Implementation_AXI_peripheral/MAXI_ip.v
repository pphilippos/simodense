// Based on a Vivado template
 
// TODO: replace the hard-coded AXI width (128-bit here) with a parameter
 
`timescale 1 ns / 1 ps

	module MAXI_ip #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Base address of targeted slave
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		// Burst Length. Supports 1, 2, 4, 8, 16, 32, 64, 128, 256 burst lengths
		parameter integer C_M_AXI_BURST_LEN	= `DL2block/128,
		parameter integer C_M_AXI_BURST_LEN_LOG2 = `DL2block_Log2-7, // Required here for Vivado >= 2020.2
		// Thread ID Width
		parameter integer C_M_AXI_ID_WIDTH	= 2,
		// Width of Address Bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 40,
		// Width of Data Bus
		parameter integer C_M_AXI_DATA_WIDTH	= 128, 
		// Width of User Write Address Bus
		parameter integer C_M_AXI_AWUSER_WIDTH	= 5,
		// Width of User Read Address Bus
		parameter integer C_M_AXI_ARUSER_WIDTH	= 5,
		// Width of User Write Data Bus
		parameter integer C_M_AXI_WUSER_WIDTH	= 5,
		// Width of User Read Data Bus
		parameter integer C_M_AXI_RUSER_WIDTH	= 5,
		// Width of User Response Bus
		parameter integer C_M_AXI_BUSER_WIDTH	= 5
	)
	(
		// Users to add ports here
		input wire reset_sig,		
        //input wire [C_M_AXI_DATA_WIDTH-1:0] WDATA_NEW,
		// User ports ends
		// Do not modify the ports beyond this line
        //output reg ACCEPTING,
        output wire [C_M_AXI_DATA_WIDTH-1:0] maxi_debug,
        
		// Initiate AXI transactions
		//input wire  VALID_NEW,
		
		
		input [`DADDR_bits-1:0] addrB,
		output reg [`DL2subblocks_Log2-1:0] dinBstrobe,
        output [`DL2block/`DL2subblocks-1:0] dinB,
        input [`DL2subblocks_Log2-1:0] doutBstrobe,
        input [`DL2block/`DL2subblocks-1:0] doutB,
        input enB,
        input weB,
        output reg readyB,
        output accR,
        output accW,
		
		
		
		// Asserts when transaction is complete
		//output wire  TXN_DONE,
		// Asserts when ERROR is detected
		//output reg  ERROR,
		
		// Global Clock Signal.
		input wire  M_AXI_ACLK,
		// Global Reset Singal. This Signal is Active Low
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address ID
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
		// Master Interface Write Address
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_AWBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		output wire  M_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		output wire [3 : 0] M_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each write transaction.
		output wire [3 : 0] M_AXI_AWQOS,
		// Optional User-defined signal in the write address channel.
		output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data.
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. This signal indicates which byte
    // lanes hold valid data. There is one write strobe
    // bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write last. This signal indicates the last transfer in a write burst.
		output wire  M_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
		// Write valid. This signal indicates that valid write
    // data and strobes are available
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    // can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
		// Write response. This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Optional User-defined signal in the write response channel
		input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
		// Write response valid. This signal indicates that the
    // channel is signaling a valid write response.
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master
    // can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address.
		output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
		// Read address. This signal indicates the initial
    // address of a read burst transaction.
		output [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_ARLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_ARSIZE,
		// Burst type. The burst type and the size information, 
    // determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_ARBURST,
		// Lock type. Provides additional information about the
    // atomic characteristics of the transfer.
		output wire  M_AXI_ARLOCK,
		// Memory type. This signal indicates how transactions
    // are required to progress through a system.
		output wire [3 : 0] M_AXI_ARCACHE,
		// Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Quality of Service, QoS identifier sent for each read transaction
		output wire [3 : 0] M_AXI_ARQOS,
		// Optional User-defined signal in the read address channel.
		output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER,
		// Write address valid. This signal indicates that
    // the channel is signaling valid read address and control information
		output wire  M_AXI_ARVALID,
		// Read address ready. This signal indicates that
    // the slave is ready to accept an address and associated control signals
		input wire  M_AXI_ARREADY,
		// Read ID tag. This signal is the identification tag
    // for the read data group of signals generated by the slave.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
		// Master Read Data
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer
		input wire [1 : 0] M_AXI_RRESP,
		// Read last. This signal indicates the last transfer in a read burst
		input wire  M_AXI_RLAST,
		// Optional User-defined signal in the read address channel.
		input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER,
		// Read valid. This signal indicates that the channel
    // is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    // accept the read data and response information.
		output wire  M_AXI_RREADY
	);

    // parameter integer C_M_AXI_BURST_LEN_LOG2 = `DL2block_Log2-7; // moved to interface for Vivado 2020.1
    
    //wire INIT_AXI_TXN;
    reg [C_M_AXI_DATA_WIDTH-1:0] FIFOin [C_M_AXI_BURST_LEN/`DL2subblocks-1:0];
    reg [C_M_AXI_DATA_WIDTH-1:0] FIFOout [C_M_AXI_BURST_LEN-1:0];
    reg [C_M_AXI_BURST_LEN_LOG2-`DL2subblocks_Log2-1:0] FIFOin_i;
    reg [C_M_AXI_BURST_LEN_LOG2-1:0] FIFOout_i;
    
    
    reg [8-1:0] burst_starts_w;
    reg [8-1:0] burst_starts_r;    
    reg [8-1:0] wnextc;
    reg [16-1:0] rnextc;
    
    reg [32-1:0] resets;
    reg [16-1:0] acount;
    
    reg [31:0] woffset;
    reg [31:0] roffset;
    
      
	// function called clogb2 that returns an integer which has the
	//value of the ceiling of the log base 2

	  // function called clogb2 that returns an integer which has the 
	  // value of the ceiling of the log base 2.                      
	  function integer clogb2 (input integer bit_depth);              
	  begin                                                           
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
	      bit_depth = bit_depth >> 1;                                 
	    end                                                           
	  endfunction                                                     

	// C_TRANSACTIONS_NUM is the width of the index counter for 
	// number of write or read transaction.
	 localparam integer C_TRANSACTIONS_NUM = $clog2/*clogb2*/(C_M_AXI_BURST_LEN/*-1*/);

	// Burst length for transactions, in C_M_AXI_DATA_WIDTHs.
	// Non-2^n lengths will eventually cause bursts across 4K address boundaries.
	 localparam integer C_MASTER_LENGTH	= 12;
	// total number of burst transfers is master length divided by burst length and burst size
	 localparam integer C_NO_BURSTS_REQ = C_MASTER_LENGTH-$clog2/*clogb2*/((C_M_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH/8)/*-1*/);
	// Example State machine to initialize counter, initialize write transactions, 
	// initialize read transactions and comparison of read data with the 
	// written data words.
	reg [31:0] icount;
	
	
	
	parameter [1:0] IDLE = 2'b00, // This state initiates AXI4Lite transaction 
			// after the state machine changes state to INIT_WRITE 
			// when there is 0 to 1 transition on INIT_AXI_TXN
		INIT_WRITE   = 2'b01, // This state initializes write transaction,
			// once writes are done, the state machine 
			// changes state to INIT_READ 
		INIT_READ = 2'b10, // This state initializes read transaction
			// once reads are done, the state machine 
			// changes state to INIT_COMPARE 
		INIT_COMPARE = 2'b11; // This state issues the status of comparison 
			// of the written data with the read data	

	 reg [1:0] mst_exec_state;

	// AXI4LITE signals
	//AXI4 internal temp signals
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awvalid;
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	reg  	axi_wlast;
	reg  	axi_wvalid;
	reg  	axi_bready;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arvalid;
	reg  	axi_rready;
	//write beat count in a burst
	reg [C_TRANSACTIONS_NUM : 0] 	write_index;
	//read beat count in a burst
	reg [C_TRANSACTIONS_NUM : 0] 	read_index;
	//size of C_M_AXI_BURST_LEN length burst in bytes
	//wire [C_TRANSACTIONS_NUM+2 : 0] 	burst_size_bytes;
	//The burst counters are used to track the number of burst transfers of C_M_AXI_BURST_LEN burst length needed to transfer 2^C_MASTER_LENGTH bytes of data.
	reg [C_NO_BURSTS_REQ : 0] 	write_burst_counter;
	reg [C_NO_BURSTS_REQ : 0] 	read_burst_counter;
	reg  	start_single_burst_write;
	reg  	start_single_burst_read;
	reg  	writes_done;
	reg  	reads_done;
	reg  	error_reg;
	reg  	compare_done;
	reg  	read_mismatch;
	reg  	burst_write_active;
	reg  	burst_read_active;
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	expected_rdata;
	//Interface response error flags
	wire  	write_resp_error;
	wire  	read_resp_error;
	wire  	wnext;
	wire  	rnext;
	reg  	init_txn_ff;
	reg  	init_txn_ff2;
	reg  	init_txn_edge;
	wire  	init_txn_pulse;


	// I/O Connections assignments

	//I/O Connections. Write Address (AW)
	assign M_AXI_AWID	= 'b0;
	//The AXI address is a concatenation of the target base address + active offset range
	assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR | (woffset/*+axi_awaddr*/);
	//Burst LENgth is number of transaction beats, minus 1
	assign M_AXI_AWLEN	= C_M_AXI_BURST_LEN - 1;
	//Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
	assign M_AXI_AWSIZE	= $clog2/*clogb2*/((C_M_AXI_DATA_WIDTH/8)/*-1*/);
	//INCR burst type is usually used, except for keyhole bursts
	assign M_AXI_AWBURST	= 2'b01;
	assign M_AXI_AWLOCK	= 1'b0;
	//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
	assign M_AXI_AWCACHE	= 4'b0010;
	assign M_AXI_AWPROT	= 3'h0;
	assign M_AXI_AWQOS	= 4'h0;
	assign M_AXI_AWUSER	= 'b1;
	assign M_AXI_AWVALID	= axi_awvalid;
	//Write Data(W)
	assign M_AXI_WDATA	= axi_wdata; //WDATA_NEW;
	//All bursts are complete and aligned in this example
	assign M_AXI_WSTRB	= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
	assign M_AXI_WLAST	= axi_wlast;
	assign M_AXI_WUSER	= 'b0;
	assign M_AXI_WVALID	= axi_wvalid;
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;
	//Read Address (AR)
	assign M_AXI_ARID	= 'b0;
	assign M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR | (roffset/*+axi_araddr*/);
	//Burst LENgth is number of transaction beats, minus 1
	assign M_AXI_ARLEN	= C_M_AXI_BURST_LEN - 1;
	//Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign M_AXI_ARSIZE	= $clog2/*clogb2*/((C_M_AXI_DATA_WIDTH/8)/*-1*/);
	//INCR burst type is usually used, except for keyhole bursts
	assign M_AXI_ARBURST	= 2'b01;
	assign M_AXI_ARLOCK	= 1'b0;
	//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
	assign M_AXI_ARCACHE	= 4'b0010;
	assign M_AXI_ARPROT	= 3'h0;
	assign M_AXI_ARQOS	= 4'h0;
	assign M_AXI_ARUSER	= 'b1;
	assign M_AXI_ARVALID	= axi_arvalid;
	//Read and Read Response (R)
	assign M_AXI_RREADY	= axi_rready;
	//Example design I/O
	assign TXN_DONE	= compare_done;
	//Burst size in bytes
	/*assign*/ localparam integer burst_size_bytes	= C_M_AXI_BURST_LEN * C_M_AXI_DATA_WIDTH/8;
	assign init_txn_pulse	= 0;//(!init_txn_ff2) && init_txn_ff;


	//Generate a pulse to initiate AXI transaction.
	always @(posedge M_AXI_ACLK)										      
	  begin                                                                        
	    // Initiates AXI transaction delay    
	    if (M_AXI_ARESETN == 0 )                                                   
	      begin                                                                    
	        init_txn_ff <= 1'b0;                                                   
	        init_txn_ff2 <= 1'b0;                                                   
	      end                                                                               
	    else                                                                       
	      begin  
	        init_txn_ff <= 1;
	        init_txn_ff2 <= init_txn_ff;                                                                 
	      end                                                                      
	  end   

    
    //reg accepting_reads;
    //reg accepting_writes;
    //assign acceptingB = accepting_reads & accepting_writes /*& not_next */&& (weB==0) && (enB==0);
    
    assign accR =!(start_single_burst_read |burst_read_active |enB);
    assign accW =!(start_single_burst_write|burst_write_active|weB);
    
    assign maxi_debug=//{woffset[15:0],FIFOout[`VLEN2/`VLEN-6][15:0]};//{3'b0,accepting_reads, 3'b0,accepting_writes, 3'b0,not_next, 3'b0,FIFOin_i,
	// 3'b0,FIFOout_i,start_single_burst_read,burst_read_active,start_single_burst_write,burst_write_active};
   {/*5'b0,accepting_reads , accepting_writes , not_next,*/rnextc/*>>(`VLEN2_Log2-`VLEN_Log2)*/,wnextc/*>>(`VLEN2_Log2-`VLEN_Log2)*/,
	  burst_starts_r, burst_starts_w};
	// woffset;
//icount;acceptingB,readyB,
    genvar j;
    for (j=0; j<`DL2block/`DL2subblocks/128; j=j+1) begin
        assign dinB[(j+1)*128-1-:128]=FIFOin[j];
    end
        
    integer i;
    always @(posedge M_AXI_ACLK)                                                      
	  begin 
	    if (reset_sig) begin                                                       
	      axi_wdata <= -1; 
	      FIFOin_i<=0;    
	      FIFOout_i<=0;  
	      //ACCEPTING<=1;   
	         
	      burst_starts_r<=0;burst_starts_w<=0;	       
	      resets<=0;     
	      wnextc<=0; rnextc<=0;     
	      accepting_reads<=1; accepting_writes<=1;    
	      readyB<=0;             
	      icount<=0;
	      dinBstrobe<=0;
	      
	      woffset <= 0; roffset <= 0;
          //else if (wnext && axi_wlast)                                                  
	      //axi_wdata <= 'b0;                                                           
	    end else begin
	    
	        burst_starts_w <= burst_starts_w + start_single_burst_write; // for debug
	        burst_starts_r <= burst_starts_r + start_single_burst_read;	 // for debug      
	        wnextc <= wnextc+(weB && (doutBstrobe==0)); // for debug
	        rnextc <= rnextc+enB; // for debug
	        
	        if (weB && (doutBstrobe==0)) woffset <= addrB;
	        if (weB) begin
	           //axi_wdata <= doutB;
	           
	           for (i=0; i<`DL2block/`DL2subblocks/128; i=i+1) begin
	               FIFOout[(doutBstrobe*(`DL2block/`DL2subblocks/128))|i]<=/*addrB|(i<<2);*//*(i<<16)|*/
	                   doutB[(i+1)*128-1-:128]; 
	           end
	        end 
	        
	        if (enB) begin
	           roffset <= addrB;
	        end 
	        
            accepting_reads<=!(start_single_burst_read|burst_read_active|enB); 
	        accepting_writes<=!(start_single_burst_write|burst_write_active|(weB!=0));
	
	        
	        axi_wdata <= FIFOout[FIFOout_i+wnext];
	        
	        FIFOout_i<=FIFOout_i+wnext; 
	        
	        if (rnext)
                FIFOin[FIFOin_i]<=M_AXI_RDATA;       
            FIFOin_i<=FIFOin_i+rnext;
            
            readyB<=0;
            if ((FIFOin_i==`DL2block/`DL2subblocks/128-1) && rnext) begin
                readyB<=1;
            end
            if (readyB) dinBstrobe<=dinBstrobe+1;
            
            
        end
      end



	//--------------------
	//Write Address Channel
	//--------------------

	// The purpose of the write address channel is to request the address and 
	// command information for the entire transaction.  It is a single beat
	// of information.

	// The AXI4 Write address channel in this example will continue to initiate
	// write commands as fast as it is allowed by the slave/interconnect.
	// The address will be incremented on each accepted address transaction,
	// by burst_size_byte to point to the next address. 

	  always @(posedge M_AXI_ACLK)                                   
	  begin                                                                
	                                                                       
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                           
	      begin                                                            
	        axi_awvalid <= 1'b0;                                           
	      end                                                              
	    // If previously not valid , start next transaction                
	    else if (~axi_awvalid && start_single_burst_write)                 
	      begin                                                            
	        axi_awvalid <= 1'b1;                                           
	      end                                                              
	    /* Once asserted, VALIDs cannot be deasserted, so axi_awvalid      
	    must wait until transaction is accepted */                         
	    else if (M_AXI_AWREADY && axi_awvalid)                             
	      begin                                                            
	        axi_awvalid <= 1'b0;                                           
	      end                                                              
	    else                                                               
	      axi_awvalid <= axi_awvalid;                                      
	    end                                                                
	                                                                       
	                                                                       
	// Next address after AWREADY indicates previous address acceptance    
	  always @(posedge M_AXI_ACLK)                                         
	  begin                                                                
	    if (M_AXI_ARESETN == 0 /*|| init_txn_pulse == 1'b1*/)                                            
	      begin                                                            
	        axi_awaddr <= 'b0;   
	        //acount<=0;                                          
	      end                                                              
	    else if (M_AXI_AWREADY && axi_awvalid)                             
	      begin                                                            
	        axi_awaddr <= 0;//axi_awaddr + /*(32*128/8)*/burst_size_bytes;//+4   
	        //acount<=acount+1;                
	      end                                                              
	    else                                                               
	      axi_awaddr <= axi_awaddr;
	      if (reset_sig) axi_awaddr <= 'b0;                                          
	    end                                                                


	//--------------------
	//Write Data Channel
	//--------------------

	//The write data will continually try to push write data across the interface.

	//The amount of data accepted will depend on the AXI slave and the AXI
	//Interconnect settings, such as if there are FIFOs enabled in interconnect.

	//Note that there is no explicit timing relationship to the write address channel.
	//The write channel has its own throttling flag, separate from the AW channel.

	//Synchronization between the channels must be determined by the user.

	//The simpliest but lowest performance would be to only issue one address write
	//and write data burst at a time.

	//In this example they are kept in sync by using the same address increment
	//and burst sizes. Then the AW and W channels have their transactions measured
	//with threshold counters as part of the user logic, to make sure neither 
	//channel gets too far ahead of each other.

	//Forward movement occurs when the write channel is valid and ready

	  assign wnext = M_AXI_WREADY & axi_wvalid;                                   
	                                                                                    
	// WVALID logic, similar to the axi_awvalid always block above                      
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                                        
	      begin                                                                         
	        axi_wvalid <= 1'b0;                                                         
	      end                                                                           
	    // If previously not valid, start next transaction                              
	    else if (~axi_wvalid && start_single_burst_write)                               
	      begin                                                                         
	        axi_wvalid <= 1'b1;                                                         
	      end                                                                           
	    /* If WREADY and too many writes, throttle WVALID                               
	    Once asserted, VALIDs cannot be deasserted, so WVALID                           
	    must wait until burst is complete with WLAST */                                 
	    else if (wnext && axi_wlast)                                                    
	      axi_wvalid <= 1'b0;                                                           
	    else                                                                            
	      axi_wvalid <= axi_wvalid;                                                     
	  end                                                                               
	                                                                                    
	                                                                                    
	//WLAST generation on the MSB of a counter underflow                                
	// WVALID logic, similar to the axi_awvalid always block above                      
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                                        
	      begin                                                                         
	        axi_wlast <= 1'b0;                                                          
	      end                                                                           
	    // axi_wlast is asserted when the write index                                   
	    // count reaches the penultimate count to synchronize                           
	    // with the last write data when write_index is b1111                           
	    else if (&(write_index[C_TRANSACTIONS_NUM-1:1])&& ~write_index[0] && wnext)  
	    //else if (/*((write_index == C_M_AXI_BURST_LEN-2 && C_M_AXI_BURST_LEN >= 2) && wnext) ||*/ (C_M_AXI_BURST_LEN == 1 ))
	      begin                                                                         
	        axi_wlast <= 1'b1;                                                          
	      end                                                                           
	    // Deassrt axi_wlast when the last write data has been                          
	    // accepted by the slave with a valid response                                  
	    else if (wnext)                                                                 
	      axi_wlast <= 1'b0;                                                            
	    else if (axi_wlast && C_M_AXI_BURST_LEN == 1)                                   
	      axi_wlast <= 1'b0;                                                            
	    else                                                                            
	      axi_wlast <= axi_wlast;                                                       
	  end                                                                               
	                                                                                    
	                                                                                    
	/* Burst length counter. Uses extra counter register bit to indicate terminal       
	 count to reduce decode logic */                                                    
	  always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 || start_single_burst_write == 1'b1)    
	      begin                                                                         
	        write_index <= 0;                                                           
	      end                                                                           
	    else if (wnext && (write_index != C_M_AXI_BURST_LEN-1))                         
	      begin                                                                         
	        write_index <= write_index + 1;                                             
	      end                                                                           
	    else                                                                            
	      write_index <= write_index;                                                   
	  end                                                                               
	                                                                                    
	                                                                                    
	/* Write Data Generator                                                             
	 Data pattern is only a simple incrementing count from 0 for each burst  */         
	 /* always @(posedge M_AXI_ACLK)                                                      
	  begin                                                                             
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                         
	      axi_wdata <= 'b1;                                                             
	    //else if (wnext && axi_wlast)                                                  
	    //  axi_wdata <= 'b0;                                                           
	    else if (wnext)                                                                 
	      axi_wdata <= axi_wdata + 1;                                                   
	    else                                                                            
	      axi_wdata <= axi_wdata;                                                       
	    end                                                                             
       */

	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	//The write response channel provides feedback that the write has committed
	//to memory. BREADY will occur when all of the data and the write address
	//has arrived and been accepted by the slave.

	//The write issuance (number of outstanding write addresses) is started by 
	//the Address Write transfer, and is completed by a BREADY/BRESP.

	//While negating BREADY will eventually throttle the AWREADY signal, 
	//it is best not to throttle the whole data channel this way.

	//The BRESP bit [1] is used indicate any errors from the interconnect or
	//slave for the entire write burst. This example will capture the error 
	//into the ERROR output. 

	  always @(posedge M_AXI_ACLK)                                     
	  begin                                                                 
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                            
	      begin                                                             
	        axi_bready <= 1'b0;                                             
	      end                                                               
	    // accept/acknowledge bresp with axi_bready by the master           
	    // when M_AXI_BVALID is asserted by slave                           
	    else if (M_AXI_BVALID && ~axi_bready)                               
	      begin                                                             
	        axi_bready <= 1'b1;                                             
	      end                                                               
	    // deassert after one clock cycle                                   
	    else if (axi_bready)                                                
	      begin                                                             
	        axi_bready <= 1'b0;                                             
	      end                                                               
	    // retain the previous value                                        
	    else                                                                
	      axi_bready <= axi_bready;                                         
	  end                                                                   
	                                                                        
	                                                                        
	//Flag any write response errors                                        
	  assign write_resp_error = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]; 


	//----------------------------
	//Read Address Channel
	//----------------------------

	//The Read Address Channel (AW) provides a similar function to the
	//Write Address channel- to provide the tranfer qualifiers for the burst.

	//In this example, the read address increments in the same
	//manner as the write address channel.

	  always @(posedge M_AXI_ACLK)                                 
	  begin                                                              
	                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                         
	      begin                                                          
	        axi_arvalid <= 1'b0;                                         
	      end                                                            
	    // If previously not valid , start next transaction              
	    else if (~axi_arvalid && start_single_burst_read)                
	      begin                                                          
	        axi_arvalid <= 1'b1; //1'b0; previously disabled the read channel                                         
	      end                                                            
	    else if (M_AXI_ARREADY && axi_arvalid)                           
	      begin                                                          
	        axi_arvalid <= 1'b0;                                         
	      end                                                            
	    else                                                             
	      axi_arvalid <= axi_arvalid;                                    
	  end                                                                
	                                                                     
	                                                                     
	// Next address after ARREADY indicates previous address acceptance  
	  always @(posedge M_AXI_ACLK)                                       
	  begin                                                              
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                          
	      begin                                                          
	        axi_araddr <= 'b0;                                           
	      end                                                            
	    else if (M_AXI_ARREADY && axi_arvalid)                           
	      begin                                                          
	        axi_araddr <= 0;//axi_araddr + burst_size_bytes;                 
	      end                                                            
	    else                                                             
	      axi_araddr <= axi_araddr;                                      
	  end                                                                


	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------

	 // Forward movement occurs when the channel is valid and ready   
	  assign rnext = M_AXI_RVALID && axi_rready;                            
	                                                                        
	                                                                        
	// Burst length counter. Uses extra counter register bit to indicate    
	// terminal count to reduce decode logic                                
	  always @(posedge M_AXI_ACLK)                                          
	  begin                                                                 
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 || start_single_burst_read)                  
	      begin                                                             
	        read_index <= 0;                                                
	      end                                                               
	    else if (rnext && (read_index != C_M_AXI_BURST_LEN-1))              
	      begin                                                             
	        read_index <= read_index + 1;                                   
	      end                                                               
	    else                                                                
	      read_index <= read_index;                                         
	  end                                                                   
	                                                                        
	                                                                        
	/*                                                                      
	 The Read Data channel returns the results of the read request          
	                                                                        
	 In this example the data checker is always able to accept              
	 more data, so no need to throttle the RREADY signal                    
	 */                                                                     
	  always @(posedge M_AXI_ACLK)                                          
	  begin                                                                 
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                  
	      begin                                                             
	        axi_rready <= 1'b0;                                             
	      end                                                               
	    // accept/acknowledge rdata/rresp with axi_rready by the master     
	    // when M_AXI_RVALID is asserted by slave                           
	    else if (M_AXI_RVALID)                       
	      begin                                      
	         if (M_AXI_RLAST && axi_rready)          
	          begin                                  
	            axi_rready <= 1'b0;                  
	          end                                    
	         else                                    
	           begin                                 
	             axi_rready <= 1'b1;               
	           end                                   
	      end                                        
	    // retain the previous value                 
	  end                                            

	 // write_burst_counter counter keeps track with the number of burst transaction initiated            
	 // against the number of burst transactions the master needs to initiate                                   
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1 )                                                                                 
	      begin                                                                                                 
	        write_burst_counter <= 'b0;                                                                         
	      end                                                                                                   
	    else if (M_AXI_AWREADY && axi_awvalid)                                                                  
	      begin                                                                                                 
	        if (write_burst_counter[C_NO_BURSTS_REQ] == 1'b0)                                                   
	          begin                                                                                             
	            write_burst_counter <= write_burst_counter + 1'b1;                                              
	            //write_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                 
	          end                                                                                               
	      end                                                                                                   
	    else                                                                                                    
	      write_burst_counter <= write_burst_counter;                                                           
	  end                                                                                                       
	                                                                                                            
	 // read_burst_counter counter keeps track with the number of burst transaction initiated                   
	 // against the number of burst transactions the master needs to initiate                                   
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
	      begin                                                                                                 
	        read_burst_counter <= 'b0;                                                                          
	      end                                                                                                   
	    else if (M_AXI_ARREADY && axi_arvalid)                                                                  
	      begin                                                                                                 
	        if (read_burst_counter[C_NO_BURSTS_REQ] == 1'b0)                                                    
	          begin                                                                                             
	            read_burst_counter <= read_burst_counter + 1'b1;                                                
	            //read_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                  
	          end                                                                                               
	      end                                                                                                   
	    else                                                                                                    
	      read_burst_counter <= read_burst_counter;                                                             
	  end                                                                                                       
	                                                                                                            
	                                                                                                            
	  //implement master command interface state machine                                                        
	  always @ ( posedge M_AXI_ACLK)                                                                            
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 1'b0 )                                                                             
	      begin
	        /*mst_exec_state      <= IDLE;                                                                
	        start_single_burst_write <= 1'b0;                                                                   
	        start_single_burst_read  <= 1'b0;                                                                   
	        compare_done      <= 1'b0;                                                                          
	        ERROR <= 1'b0;  */
	        start_single_burst_write <= 1'b0; 
	        start_single_burst_read  <= 1'b0;
	      end else begin
	        start_single_burst_write <=/*(burst_write_active==0) &&*/ (weB && (doutBstrobe==0));//(burst_write_active==0) && ( 
	             //((FIFO_i_in[C_M_AXI_BURST_LEN_LOG2]==1)&&(FIFO_i_out== 0)) ||
	             //((FIFO_i_in[C_M_AXI_BURST_LEN_LOG2]==0)&&(FIFO_i_out==C_M_AXI_BURST_LEN)) );
	        start_single_burst_read <= /*(burst_read_active==0) &&*/ enB;
	             
	        if (start_single_burst_write) start_single_burst_write<=0;
	        if (start_single_burst_read ) start_single_burst_read <=0;
	      end
	  end
                                                                                             
	  // burst_write_active signal is asserted when there is a burst write transaction                          
	  // is initiated by the assertion of start_single_burst_write. burst_write_active                          
	  // signal remains asserted until the burst write is accepted by the slave                                 
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
	      burst_write_active <= 1'b0;                                                                           
	                                                                                                            
	    //The burst_write_active is asserted when a write burst transaction is initiated                        
	    else if (start_single_burst_write)                                                                      
	      burst_write_active <= 1'b1;                                                                           
	    else if (M_AXI_BVALID && axi_bready)                                                                    
	      burst_write_active <= 0;                                                                              
	  end                                                                                                       
	                                                                                                            
	 // Check for last write completion.                                                                        
	                                                                                                            
	 // This logic is to qualify the last write count with the final write                                      
	 // response. This demonstrates how to confirm that a write has been                                        
	 // committed.                                                                                              
	                                                                                                            
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
	      writes_done <= 1'b0;                                                                                  
	                                                                                                            
	    //The writes_done should be associated with a bready response                                           
	    //else if (M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
	    else if (M_AXI_BVALID && (write_burst_counter[C_NO_BURSTS_REQ]) && axi_bready)                          
	      writes_done <= 1'b1;                                                                                  
	    else                                                                                                    
	      writes_done <= writes_done;                                                                           
	    end                                                                                                     
	                                                                                                            
	  // burst_read_active signal is asserted when there is a burst write transaction                           
	  // is initiated by the assertion of start_single_burst_write. start_single_burst_read                     
	  // signal remains asserted until the burst read is accepted by the master                                 
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1) begin                                                                                
	      burst_read_active <= 1'b0;                                                                            
        //The burst_write_active is asserted when a write burst transaction is initiated                        
	    end else if (start_single_burst_read) begin                                                                      
	      burst_read_active <= 1'b1;                                                                            
	    end else if (M_AXI_RVALID && axi_rready && M_AXI_RLAST) begin                                                     
	      burst_read_active <= 0;  
	    end 	                                                                        
	  end                                                                                                     
	                                                                                                            
	                                                                                                            
	 // Check for last read completion.                                                                         
	                                                                                                            
	 // This logic is to qualify the last read count with the final read                                        
	 // response. This demonstrates how to confirm that a read has been                                         
	 // committed.                                                                                              
	                                                                                                            
	  always @(posedge M_AXI_ACLK)                                                                              
	  begin                                                                                                     
	    if (M_AXI_ARESETN == 0 || init_txn_pulse == 1'b1)                                                                                 
	      reads_done <= 1'b0;                                                                                   
	                                                                                                            
	    //The reads_done should be associated with a rready response                                            
	    //else if (M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
	    else if (M_AXI_RVALID && axi_rready && (read_index == C_M_AXI_BURST_LEN-1) && (read_burst_counter[C_NO_BURSTS_REQ]))
	      reads_done <= 1'b1;                                                                                   
	    else                                                                                                    
	      reads_done <= reads_done;                                                                             
	    end                                                                                                     

	// Add user logic here

	// User logic ends

	endmodule
