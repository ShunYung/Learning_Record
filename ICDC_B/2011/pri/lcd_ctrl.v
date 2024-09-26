`timescale 1ns/100ps


`define ICDC2011_DS #0.5


module LCD_CTRL(
 input clk
,input reset
,input [7:0] IROM_Q
,input [2:0] cmd
,input cmd_valid
,output reg IROM_EN
//,output IROM_EN
,output reg [5:0] IROM_A
,output reg IRB_RW
//,output reg [7:0] IRB_D
,output [7:0] IRB_D
,output reg [5:0] IRB_A
,output busy
,output reg done
);
// IROM_A Buffer
reg     [ 7:0]  irom_buf        [0:63];
reg             buf_last;
reg             start;
reg             start_d;
// Step1. IROM_A Read data to controller

wire    [ 5:0]  IROM_A_pre      =   (&IROM_A | IROM_EN)             ?       6'd0    :
                                    ~IROM_EN            ? IROM_A +6'd1  :       IROM_A  ;

wire            buf_last_pre    =   &IROM_A             ?       1'b1    : 1'b0  ;
wire            start_pre       =   1'b1;
wire            IROM_EN_pre     =   buf_last            ?       1'b1    :
                                    ~start              ?       1'b0    :
                                                                            IROM_EN;
//assign          IROM_EN         =   buf_last            ?       1'b1    : ~start;

// Step2. receive CMD
reg             write_cmd;
reg             write_cmd_n;
reg             sh_u_cmd ;
reg             sh_d_cmd ;
reg             sh_l_cmd ;
reg             sh_r_cmd ;
reg             avg_cmd  ;
reg             mir_x_cmd;
reg             mir_y_cmd;



wire            write_cmd_pre   =   cmd_valid && (cmd == 3'd0) ? 1'b1 :  write_cmd ;    
wire            write_cmd_n_pre =   write_cmd;
wire            sh_u_cmd_pre    =   cmd_valid && (cmd == 3'd1) ? 1'b1 :
                                    busy & sh_u_cmd            ? 1'b0 :  sh_u_cmd  ;    
wire            sh_d_cmd_pre    =   cmd_valid && (cmd == 3'd2) ? 1'b1 :  
                                    busy & sh_d_cmd            ? 1'b0 :  sh_d_cmd  ;    
wire            sh_l_cmd_pre    =   cmd_valid && (cmd == 3'd3) ? 1'b1 :
                                    busy & sh_l_cmd            ? 1'b0 :  sh_l_cmd  ;    
wire            sh_r_cmd_pre    =   cmd_valid && (cmd == 3'd4) ? 1'b1 :
                                    busy & sh_r_cmd            ? 1'b0 :  sh_r_cmd  ;    
wire            avg_cmd_pre     =   cmd_valid && (cmd == 3'd5) ? 1'b1 :
                                    busy & avg_cmd             ? 1'b0 :  avg_cmd  ;    
wire            mir_x_cmd_pre   =   cmd_valid && (cmd == 3'd6) ? 1'b1 :
                                    busy & mir_x_cmd           ? 1'b0 :  mir_x_cmd ;    
wire            mir_y_cmd_pre   =   cmd_valid && (cmd == 3'd7) ? 1'b1 :
                                    busy & mir_y_cmd           ? 1'b0 :  mir_y_cmd ;    

wire            cmdvalid        =   write_cmd |
                                    sh_u_cmd  |
                                    sh_d_cmd  |
                                    sh_l_cmd  |
                                    sh_r_cmd  |
                                    avg_cmd   |
                                    mir_x_cmd |
                                    mir_y_cmd    ;

reg     [ 2:0]  point_x, point_y;


wire    [ 2:0]  point_x_pre     =  
                                    sh_l_cmd    ? ( (point_x == 3'd1) ? 3'd1 : point_x -3'd1  )       :
                                    sh_r_cmd    ? ( (&point_x)        ? 3'd7 : point_x +3'd1  )       : point_x;

wire    [ 2:0]  point_y_pre     =      
                                    sh_u_cmd    ? ( (point_y == 3'd1) ? 3'd1 : point_y -3'd1  )       :
                                    sh_d_cmd    ? ( (&point_y)        ? 3'd7 : point_y +3'd1  )       : point_y;

//wire    [ 5:0] {point_y_pre,point_x_pre}        =      
//                                                    sh_l_cmd    ? ( (point_x == 3'd1) ? 3'd1 : point_x -3'd1  )       :
//                                                    sh_r_cmd    ? ( (&point_x)        ? 3'd7 : point_x +3'd1  )       : point_x
//                                                    sh_u_cmd    ? ( (point_y == 3'd1) ? 3'd1 : point_y -3'd1  )       :
//                                                    sh_d_cmd    ? ( (&point_y)        ? 3'd7 : point_y +3'd1  )       : point_y


//wire    [ 7:0]  irom_avg        =   (irom_buf[ point_x    + 8*point_y]     +
//                                     irom_buf[(point_x-1) + 8*point_y]     +
//                                     irom_buf[ point_x    + 8*(point_y-1)] +
//                                     irom_buf[(point_x-1) + 8*(point_y-1)] ) /4 ;

wire    [ 7:0]  irom_avg        =   (irom_buf[{point_y,point_x}]         +
                                     irom_buf[{point_y,point_x} - 6'd1]  +
                                     irom_buf[{point_y,point_x} - 6'd8]  +
                                     irom_buf[{point_y,point_x} - 6'd9] ) /4 ;

wire            stat_flag       = start ^ start_d;


assign          busy            =   IROM_EN & stat_flag ?  1'b1   :
                                   ~IROM_EN             ?  1'b1   :
                                    (cmdvalid)          ?  1'b1   :
                                    ~start              ?  1'b1   :
                                                            1'b0;


wire            IRB_RW_pre      =   (write_cmd )    ? 1'b0   :   1'b1;


wire    [ 5:0]  IRB_A_pre       =   &IRB_A              ?       6'd0    :                        
                                    ~IRB_RW             ? IRB_A +6'd1   :       IRB_A  ;

//wire    [ 7:0]  IRB_D_pre       =   ~IRB_RW             ? ( IRB_A== 6'd0 ?  irom_buf[IRB_A]    :   irom_buf[IRB_A_pre]  ): IRB_D    ;
assign     IRB_D        =   {8{~IRB_RW}} & irom_buf[IRB_A] ;




// Step 3. Done
wire            done_pre        =   &IRB_A ? 1'b1 : done ;

always @(negedge clk or posedge reset)
begin
   if (reset)
   begin
       IROM_A                   <= `ICDC2011_DS 6'd0;
       IROM_EN                  <= `ICDC2011_DS 1'd1;
       buf_last                 <= `ICDC2011_DS 1'd0;
//       IRB_D                    <= `ICDC2011_DS 1'd0;
       IRB_A                    <= `ICDC2011_DS 1'd0;
       IRB_RW                   <= `ICDC2011_DS 1'd1;
       write_cmd_n     <= `ICDC2011_DS 1'd0;
       done     <= `ICDC2011_DS 1'd0;
       point_x     <= `ICDC2011_DS 3'd4;
       point_y     <= `ICDC2011_DS 3'd4;

   end
   else
   begin

       IROM_A                   <= `ICDC2011_DS IROM_A_pre;
       IROM_EN                  <= `ICDC2011_DS IROM_EN_pre;
       buf_last                 <= `ICDC2011_DS buf_last_pre;
//       IRB_D                    <= `ICDC2011_DS IRB_D_pre;
       IRB_A                    <= `ICDC2011_DS IRB_A_pre;
       IRB_RW                   <= `ICDC2011_DS IRB_RW_pre;
       done     <= `ICDC2011_DS done_pre;
       point_x     <= `ICDC2011_DS point_x_pre;
       point_y     <= `ICDC2011_DS point_y_pre;
   end

end

wire   [7:0] buf_0 = irom_buf[0];
wire   [7:0] buf_1 = irom_buf[1];
wire   [7:0] buf_2 = irom_buf[2];
wire   [7:0] buf_3 = irom_buf[3];
wire   [7:0] buf_4 = irom_buf[4];
wire   [7:0] buf_5 = irom_buf[5];
wire   [7:0] buf_6 = irom_buf[6];
wire   [7:0] buf_63= irom_buf[63];



always @(posedge clk )
begin
   if (~IROM_EN && (|IROM_A))
   begin
       irom_buf[IROM_A-6'd1]            <= `ICDC2011_DS IROM_Q;
   end
   else if(buf_last)
   begin

       irom_buf[63]                     <= `ICDC2011_DS IROM_Q;
   end
   else if(avg_cmd)
   begin
       irom_buf[{point_y,point_x}       ]          <= `ICDC2011_DS irom_avg;
       irom_buf[{point_y,point_x} - 6'd1]          <= `ICDC2011_DS irom_avg;
       irom_buf[{point_y,point_x} - 6'd8]          <= `ICDC2011_DS irom_avg;
       irom_buf[{point_y,point_x} - 6'd9]          <= `ICDC2011_DS irom_avg;
   end

   else if(mir_x_cmd)
   begin
       irom_buf[{point_y,point_x}       ]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd8];
       irom_buf[{point_y,point_x} - 6'd1]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd9];
       irom_buf[{point_y,point_x} - 6'd8]          <= `ICDC2011_DS irom_buf[{point_y,point_x}       ];
       irom_buf[{point_y,point_x} - 6'd9]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd1]    ;
   end

   else if(mir_y_cmd)
   begin
       irom_buf[{point_y,point_x}       ]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd1]    ;
       irom_buf[{point_y,point_x} - 6'd1]          <= `ICDC2011_DS irom_buf[{point_y,point_x}       ]    ;
       irom_buf[{point_y,point_x} - 6'd8]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd9];
       irom_buf[{point_y,point_x} - 6'd9]          <= `ICDC2011_DS irom_buf[{point_y,point_x} - 6'd8];
   end





   

end


always @(posedge clk or posedge reset)
begin
   if (reset)
   begin

        write_cmd       <= `ICDC2011_DS 1'd0;

        sh_u_cmd        <= `ICDC2011_DS 1'd0;
        sh_d_cmd        <= `ICDC2011_DS 1'd0;
        sh_l_cmd        <= `ICDC2011_DS 1'd0;
        sh_r_cmd        <= `ICDC2011_DS 1'd0;
        avg_cmd         <= `ICDC2011_DS 1'd0;
        mir_x_cmd       <= `ICDC2011_DS 1'd0;
        mir_y_cmd       <= `ICDC2011_DS 1'd0;                
        start           <= `ICDC2011_DS 1'd0;        
        start_d           <= `ICDC2011_DS 1'd0;        
   end
   else
   begin

        write_cmd       <= `ICDC2011_DS write_cmd_pre;

        sh_u_cmd        <= `ICDC2011_DS sh_u_cmd_pre ;
        sh_d_cmd        <= `ICDC2011_DS sh_d_cmd_pre ;
        sh_l_cmd        <= `ICDC2011_DS sh_l_cmd_pre ;
        sh_r_cmd        <= `ICDC2011_DS sh_r_cmd_pre ;
        avg_cmd         <= `ICDC2011_DS avg_cmd_pre  ;
        mir_x_cmd       <= `ICDC2011_DS mir_x_cmd_pre;
        mir_y_cmd       <= `ICDC2011_DS mir_y_cmd_pre;                
        start           <= `ICDC2011_DS start_pre;        
        start_d           <= `ICDC2011_DS start;        
   end

end


endmodule