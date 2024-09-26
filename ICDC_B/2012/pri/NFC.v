`timescale 1ns/100ps

`define ICDC2012 #0.5

module NFC(

 input clk
,input rst
,output reg done
,inout [7:0] F_IO_A
,output F_CLE_A
,output F_ALE_A
,output reg F_REN_A
,output F_WEN_A
,input  F_RB_A  
,input  F_RB_B
,inout [7:0] F_IO_B
,output F_CLE_B
,output F_ALE_B
,output F_REN_B
,output F_WEN_B

);



reg     [1:0]   addr_cnt;
reg     [2:0]   state   ;
reg     [17:0]  addr_cnta;
reg             rc_tg;
reg             rc_flag;

//state machine

wire    [2:0]   state_pre         = (state == 3'd0 )    ? 3'd1                                                          :
                                    (state == 3'd1 )    ? 3'd2                                                          :
                                    (state == 3'd2 )    ? ( addr_cnt== 2'd2 ? 3'd3 : 3'd2  )                            :
                                    (state == 3'd3 )    ? ( F_RB_A ? 3'd4 : 3'd3 )                                      :
                                    (state == 3'd4 )    ? ( ( addr_cnta[8:0] == 9'd511) && ~rc_flag ? 3'd5 : 3'd4)      :
                                    (state == 3'd5 )    ? 3'd6                                                          :
                                    (state == 3'd6 )    ? (
                                                            ( F_RB_B && addr_cnta == 18'd262143 ) ? 3'd7 :
                                                              F_RB_B                              ? 3'd0 : 3'd6 )       :
                                    (state == 3'd7 )    ? 3'd7                                                          :
                                                          3'd0
                                                                ;



wire    [1:0]   addr_cnt_pre      = (addr_cnt == 3'd2 ) ? 2'd0            :  
                                    (state == 3'd2 )    ? addr_cnt + 2'd1 : addr_cnt ;

assign          F_CLE_A           = (state == 3'd1) ? 1'd1 : 1'd0;
assign          F_CLE_B           = (state == 3'd1 || state == 3'd5  ) ? 1'd1 : 1'd0;

assign          F_WEN_A           = ( (state == 3'd1) || (state == 3'd2) ) ? ~clk : 1'b1 ;
assign          F_WEN_B           = ( F_CLE_B || state == 3'd2 || ~F_REN_A ) ? ~clk : 1'b0;


assign          F_ALE_A           = (state == 3'd2) ? 1'd1 : 1'd0;
assign          F_ALE_B           = (state == 3'd2) ? 1'd1 : 1'd0;




wire            rc_flag_pre       = (state == 3'd4)            ? 1'b0 :  
                                    (state == 3'd5)            ? 1'b1 : rc_flag;    
wire            F_REN_A_pre       = (state == 3'd4)     ? ~F_REN_A : F_REN_A;
assign          F_REN_B           = 1'b1;

wire    [17:0]  addr_cnta_add1    = (addr_cnta == 18'd0) ? addr_cnta : addr_cnta + 18'd1;



wire            out_en_a          = (state == 3'd1 || state == 3'd2) ? 1'd1 : 1'd0;
wire            out_en_b          = 1'd1;


reg     [7:0]   out_a;
wire    [7:0]   out_a_pre         = (state == 3'd0)                             ? {7'd0, addr_cnta_add1[8]}     :
                                    (state == 3'd1)                             ? addr_cnta_add1[7:0]           :
                                    (state == 3'd2) && (addr_cnt == 2'd0)       ? addr_cnta_add1[16:9]          :
                                    (state == 3'd2) && (addr_cnt == 2'd1)       ? {7'd0, addr_cnta_add1[17]}    : out_a;

wire    [7:0]   out_b_pre         =
                                    (state == 3'd1) ? 8'h80           :
                                    (state == 3'd2) ? out_a           :
                                    (state == 3'd5) ? 8'h10           : F_IO_A;


assign          F_IO_A            = out_en_a ? out_a : 'bz;
assign          F_IO_B            = out_en_b ? out_b_pre : 'bz;


wire            done_pre         = (state == 3'd7) ;

always@(posedge clk or posedge rst)
begin
if(rst)
            F_REN_A    <= `ICDC2012 1'b1;
        else
            F_REN_A    <= `ICDC2012 F_REN_A_pre;
end


always@(posedge clk or posedge rst)
begin
if(rst)
            addr_cnt    <= `ICDC2012 2'd0;
        else
            addr_cnt    <= `ICDC2012 addr_cnt_pre;
end

always@(posedge clk or posedge rst)
begin
if(rst)
            state       <= `ICDC2012 3'd0;
        else
            state       <= `ICDC2012 state_pre;
end


always@(posedge clk or posedge rst)
begin
if(rst)
            out_a       <= `ICDC2012 8'd0;
        else
            out_a       <= `ICDC2012 out_a_pre;
end

always@(posedge clk or posedge rst)
begin
if(rst)
            rc_tg       <= `ICDC2012 1'b1;
        else if (state == 3'd4 )  
            rc_tg       <= `ICDC2012 ~rc_tg;
end

always@(posedge clk or posedge rst)
begin
if(rst)
            addr_cnta       <= `ICDC2012 {18'd262143,1'b1};
        else if (state == 3'd4 && rc_tg )  
            addr_cnta       <= `ICDC2012 addr_cnta + 19'd1;
end
//always@(posedge clk or posedge rst)
//begin
// if(rst)
//            {addr_cnta,rc_tg}       <= `ICDC2012 {18'd262143,1'b1};
//        else if (state == 3'd4 )  
//            {addr_cnta,rc_tg}       <= `ICDC2012 {addr_cnta,rc_tg} + 19'd1;
//end

always@(posedge clk or posedge rst)
begin
if(rst)
            done       <= `ICDC2012 1'd0;
        else
            done       <= `ICDC2012 done_pre;
end

always@(posedge clk or posedge rst)
begin
if(rst)
            rc_flag       <= `ICDC2012 1'd1;
        else
            rc_flag       <= `ICDC2012 rc_flag_pre;
end


endmodule