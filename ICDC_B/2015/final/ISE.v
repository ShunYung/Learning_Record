`timescale 1ns/10ps


`define ICDC2015_DS #0.5


module ISE(
 input               clk
,input               reset
,input       [4:0]   image_in_index
,input       [23:0]  pixel_in
,output reg          busy
,output reg          out_valid
,output reg  [1:0]   color_index
,output reg  [4:0]   image_out_index
);

reg     [21:0]  sum;
reg     [13:0]  cnt;
reg     [15:0]  avg_arr         [0:31];
reg     [ 4:0]  index_arr       [0:31];
reg     [ 1:0]  color_arr       [0:31];
reg     [ 4:0]  i;
reg             sort_end,sort_period;


// R/G/B data
wire    [7:0]   r_data          =       pixel_in[23:16];
wire    [7:0]   g_data          =       pixel_in[15: 8];
wire    [7:0]   b_data          =       pixel_in[ 7: 0];


// Judge R/G/B color condition for 1 pixel

wire            r_en            =       ( r_data >= g_data ) && ( r_data >= b_data );
wire            g_en            =       ( g_data >  r_data ) && ( g_data >= b_data );
wire            b_en            =       ( b_data >  r_data ) && ( b_data >  g_data );


// pixel counter for 1 image_index ( 0~16383 )
reg     [13:0]  pixel_cnt;


wire    [13:0]  pixel_cnt_pre   =    busy | ( &pixel_cnt[13:0] )       ?           14'd0           :
//                                   ( r_en | g_en | b_en )   ?   pixel_cnt + 14'd1       :
//                                                                pixel_cnt;
                                                                           pixel_cnt + 14'd1       ;



// R/G/B number count for 1 image_index ( 1 image total piexl = 16384 )
reg     [13:0]  r_cnt, g_cnt, b_cnt;

wire    [13:0]  r_cnt_pre       =       busy    ?       14'd0           :
                                        r_en    ?   r_cnt + 14'd1       :
                                                    r_cnt;

wire    [13:0]  g_cnt_pre       =       busy    ?       14'd0           :
                                        g_en    ?   g_cnt + 14'd1       :
                                                    g_cnt;

wire    [13:0]  b_cnt_pre       =       busy    ?       14'd0           :
                                        b_en    ?   b_cnt + 14'd1       :
                                                    b_cnt;



// R/G/B individual summation for 1 image_index ( 256*16384 = 2^22 )
reg     [21:0]  r_sum, g_sum, b_sum;

wire    [21:0]  r_sum_pre       =       busy    ?       22'd0           :
                                        r_en    ?   r_sum + r_data      :
                                                    r_sum;

wire    [21:0]  g_sum_pre       =       busy    ?       22'd0           :
                                        g_en    ?   g_sum + g_data      :
                                                    g_sum;

wire    [21:0]  b_sum_pre       =       busy    ?       22'd0           :
                                        b_en    ?   b_sum + b_data      :
                                                    b_sum;


// R/G/B individual summation for 1 image_index ( 256*16384 = 2^22 )

reg     [ 1:0]  image;
wire    [ 1:0]  image_pre       =    //           busy                             ?   2'h0        :
                                    ( &pixel_cnt[13:0] )                         ?
                                     ( ( r_cnt > g_cnt ) && ( r_cnt > b_cnt )    ?   2'h0        :
                                       ( g_cnt > r_cnt ) && ( g_cnt > b_cnt )    ?   2'h1        :
                                                                                     2'h2    )   :  image;

// keep_busy
reg             busy_keep;
wire            busy_keep_pre   =       (&image_in_index)  && (~|pixel_cnt_pre[13:0]) ? 1'b1 : busy_keep  ;


// busy
wire            busy_pre        =  
                                    ( busy_keep )?  1'b1   :                                                
                                   ( &pixel_cnt[13:0] ) ? 1'b1:1'b0 ;


reg             image_in_index_keep;
wire            image_in_index_keep_pre   =       (&image_in_index) ? 1'b1 : image_in_index_keep  ;
wire     [5:0]  image_in_index_1          =       busy_keep_pre     ? 6'd32 :  image_in_index ;

// sort end
//wire            sort_end_pre    =  busy_keep_pre ? (i==image_in_index_1-1'd1)& sort_period  : ( i== ( ~ ( ~image_in_index_1 + 5'd1 ) ) ) & sort_period  ;
wire            sort_end_pre    =   ( i== ( ~ ( ~image_in_index_1 + 6'd1 ) ) ) & sort_period  ;


reg             final_sort_end;
wire            final_sort_end_pre =   sort_end_pre & busy_keep ? 1'b1 : final_sort_end;
// sort period
wire            sort_period_pre =   ( final_sort_end| sort_end_pre) ? 1'b0:
                                    ( busy )      ? 1'b1 :
                                       sort_period;


reg      [4:0]  out_cnt;    
wire     [4:0]  out_cnt_pre             =       out_valid ? out_cnt +1 : out_cnt;
// outvaild
wire            out_valid_pre           =  (&out_cnt)  ? 1'b0 :   final_sort_end  & busy_keep ;

wire     [1:0]  color_index_pre         =       out_valid_pre ? color_arr[out_cnt_pre] : color_index;

wire     [4:0]  image_out_index_pre     =       out_valid_pre ? index_arr[out_cnt_pre] : image_out_index;

// sort period counter
wire          [4:0]  i_pre           =   ( sort_end_pre        ) ?   5'd0   :
                                           sort_period           ?   i+5'd1 :
                                                                          i ;


wire     [15:0]  avg_arr_tmp0        =  avg_arr[0]  ;
wire     [ 4:0]  index_arr_tmp0      =  index_arr[0];
wire     [ 1:0]  color_arr_tmp0      =  color_arr[0];


wire     [15:0]  avg_arr_tmp1        =  avg_arr[1]  ;
wire     [ 4:0]  index_arr_tmp1      =  index_arr[1];
wire     [ 1:0]  color_arr_tmp1      =  color_arr[1];

wire     [15:0]  avg_arr_tmp2        =  avg_arr[2]  ;
wire     [ 4:0]  index_arr_tmp2      =  index_arr[2];
wire     [ 1:0]  color_arr_tmp2      =  color_arr[2];

wire     [15:0]  avg_arr_tmp3        =  avg_arr[3]  ;
wire     [ 4:0]  index_arr_tmp3      =  index_arr[3];
wire     [ 1:0]  color_arr_tmp3      =  color_arr[3];

wire     [15:0]  avg_arr_tmp4        =  avg_arr[4]  ;
wire     [ 4:0]  index_arr_tmp4      =  index_arr[4];
wire     [ 1:0]  color_arr_tmp4      =  color_arr[4];

wire     [15:0]  avg_arr_tmp5        =  avg_arr[5]  ;
wire     [ 4:0]  index_arr_tmp5      =  index_arr[5];
wire     [ 1:0]  color_arr_tmp5      =  color_arr[5];

wire     [15:0]  avg_arr_tmp6        =  avg_arr[6]  ;
wire     [ 4:0]  index_arr_tmp6      =  index_arr[6];
wire     [ 1:0]  color_arr_tmp6      =  color_arr[6];


wire     [15:0]  avg_arr_tmp7        =  avg_arr[7]  ;
wire     [ 4:0]  index_arr_tmp7      =  index_arr[7];
wire     [ 1:0]  color_arr_tmp7      =  color_arr[7];

wire     [15:0]  avg_arr_tmp8        =  avg_arr[8]  ;
wire     [ 4:0]  index_arr_tmp8      =  index_arr[8];
wire     [ 1:0]  color_arr_tmp8      =  color_arr[8];

wire     [15:0]  avg_arr_tmp9        =  avg_arr[9]  ;
wire     [ 4:0]  index_arr_tmp9      =  index_arr[9];
wire     [ 1:0]  color_arr_tmp9      =  color_arr[9];

wire     [15:0]  avg_arr_tmp10        =  avg_arr[10]  ;
wire     [ 4:0]  index_arr_tmp10      =  index_arr[10];
wire     [ 1:0]  color_arr_tmp10      =  color_arr[10];

wire     [15:0]  avg_arr_tmp11        =  avg_arr[11]  ;
wire     [ 4:0]  index_arr_tmp11      =  index_arr[11];
wire     [ 1:0]  color_arr_tmp11      =  color_arr[11];

wire     [15:0]  avg_arr_tmp12        =  avg_arr[12]  ;
wire     [ 4:0]  index_arr_tmp12      =  index_arr[12];
wire     [ 1:0]  color_arr_tmp12      =  color_arr[12];

wire     [15:0]  avg_arr_tmp13        =  avg_arr[13]  ;
wire     [ 4:0]  index_arr_tmp13      =  index_arr[13];
wire     [ 1:0]  color_arr_tmp13      =  color_arr[13];


wire     [15:0]  avg_arr_tmp14        =  avg_arr[14]  ;
wire     [ 4:0]  index_arr_tmp14      =  index_arr[14];
wire     [ 1:0]  color_arr_tmp14      =  color_arr[14];

wire     [15:0]  avg_arr_tmp15        =  avg_arr[15]  ;
wire     [ 4:0]  index_arr_tmp15      =  index_arr[15];
wire     [ 1:0]  color_arr_tmp15      =  color_arr[15];

wire     [15:0]  avg_arr_tmp16        =  avg_arr[16]  ;
wire     [ 4:0]  index_arr_tmp16      =  index_arr[16];
wire     [ 1:0]  color_arr_tmp16      =  color_arr[16];

wire     [15:0]  avg_arr_tmp17        =  avg_arr[17]  ;
wire     [ 4:0]  index_arr_tmp17      =  index_arr[17];
wire     [ 1:0]  color_arr_tmp17      =  color_arr[17];

wire     [15:0]  avg_arr_tmp18        =  avg_arr[18]  ;
wire     [ 4:0]  index_arr_tmp18      =  index_arr[18];
wire     [ 1:0]  color_arr_tmp18      =  color_arr[18];

wire     [15:0]  avg_arr_tmp19        =  avg_arr[19]  ;
wire     [ 4:0]  index_arr_tmp19      =  index_arr[19];
wire     [ 1:0]  color_arr_tmp19      =  color_arr[19];

wire     [15:0]  avg_arr_tmp20        =  avg_arr[20]  ;
wire     [ 4:0]  index_arr_tmp20      =  index_arr[20];
wire     [ 1:0]  color_arr_tmp20      =  color_arr[20];

wire     [15:0]  avg_arr_tmp21        =  avg_arr[21]  ;
wire     [ 4:0]  index_arr_tmp21      =  index_arr[21];
wire     [ 1:0]  color_arr_tmp21      =  color_arr[21];


wire     [15:0]  avg_arr_tmp22        =  avg_arr[22]  ;
wire     [ 4:0]  index_arr_tmp22      =  index_arr[22];
wire     [ 1:0]  color_arr_tmp22      =  color_arr[22];

wire     [15:0]  avg_arr_tmp23        =  avg_arr[23]  ;
wire     [ 4:0]  index_arr_tmp23      =  index_arr[23];
wire     [ 1:0]  color_arr_tmp23      =  color_arr[23];


wire     [15:0]  avg_arr_tmp24        =  avg_arr[24]  ;
wire     [ 4:0]  index_arr_tmp24      =  index_arr[24];
wire     [ 1:0]  color_arr_tmp24      =  color_arr[24];

wire     [15:0]  avg_arr_tmp25        =  avg_arr[25]  ;
wire     [ 4:0]  index_arr_tmp25      =  index_arr[25];
wire     [ 1:0]  color_arr_tmp25      =  color_arr[25];


wire     [15:0]  avg_arr_tmp26        =  avg_arr[26]  ;
wire     [ 4:0]  index_arr_tmp26      =  index_arr[26];
wire     [ 1:0]  color_arr_tmp26      =  color_arr[26];

wire     [15:0]  avg_arr_tmp27        =  avg_arr[27]  ;
wire     [ 4:0]  index_arr_tmp27      =  index_arr[27];
wire     [ 1:0]  color_arr_tmp27      =  color_arr[27];


wire     [15:0]  avg_arr_tmp28        =  avg_arr[28]  ;
wire     [ 4:0]  index_arr_tmp28      =  index_arr[28];
wire     [ 1:0]  color_arr_tmp28      =  color_arr[28];

wire     [15:0]  avg_arr_tmp29        =  avg_arr[29]  ;
wire     [ 4:0]  index_arr_tmp29      =  index_arr[29];
wire     [ 1:0]  color_arr_tmp29      =  color_arr[29];



wire     [15:0]  avg_arr_tmp30        =  avg_arr[30]  ;
wire     [ 4:0]  index_arr_tmp30      =  index_arr[30];
wire     [ 1:0]  color_arr_tmp30      =  color_arr[30];

wire     [15:0]  avg_arr_tmp31        =  avg_arr[31]  ;
wire     [ 4:0]  index_arr_tmp31      =  index_arr[31];
wire     [ 1:0]  color_arr_tmp31      =  color_arr[31];







//wire     [15:0]  avg_arr_tmp        ;
//wire     [ 4:0]  index_arr_tmp      ;
//wire     [ 1:0]  color_arr_tmp      ;




always @(*)
begin
    case(image_pre)
        2'h0 : cnt = r_cnt;
        2'h1 : cnt = g_cnt;
        2'h2 : cnt = b_cnt;
       default : cnt = 14'd0 ;
    endcase
end


always @(*)
begin
    case(image_pre)
        2'h0 : sum = r_sum;
        2'h1 : sum = g_sum;
        2'h2 : sum = b_sum;
       default : sum = 22'd0 ;
    endcase
end

// R/G/B average color for 1 image_index ( 256*16384 = 2^22 )
reg     [15:0]  image_avg ;
wire    [15:0]  image_avg_pre       =       {sum,8'd0} / cnt ;

//always @(posedge clk or posedge reset  )
always @(posedge clk )
begin
    if( &pixel_cnt[13:0] & busy_keep_pre )
    begin
        color_arr[image_in_index_1-1]  <= `ICDC2015_DS     image_pre ;
        avg_arr[image_in_index_1-1]    <= `ICDC2015_DS     image_avg_pre ;
        index_arr[image_in_index_1-1]  <= `ICDC2015_DS     image_in_index_1-1;
    end

    else if( &pixel_cnt[13:0] )
    begin
        color_arr[image_in_index_1]  <= `ICDC2015_DS     image_pre ;
        avg_arr[image_in_index_1]    <= `ICDC2015_DS     image_avg_pre ;
        index_arr[image_in_index_1]  <= `ICDC2015_DS     image_in_index_1;
    end
   
//  else if(sort_period && busy_keep  )
//    begin
//
//        if( color_arr[i] < color_arr [image_in_index_1] )
//        begin
//
//        end
//        
//        else if ( ( avg_arr[i] < avg_arr[image_in_index_1] ) && ( color_arr[i] ==color_arr [image_in_index_1] )  )
//        begin
//
//        end    
//
//        else
//        begin
//
//
//            color_arr[i]  <= `ICDC2015_DS  color_arr[image_in_index_1];
//            avg_arr[i]    <= `ICDC2015_DS  avg_arr[image_in_index_1]  ;
//            index_arr[i]  <= `ICDC2015_DS  index_arr[image_in_index_1];
//
//
//            color_arr[image_in_index_1] <= `ICDC2015_DS  color_arr[i];
//            avg_arr[image_in_index_1]   <= `ICDC2015_DS  avg_arr[i]  ;
//            index_arr[image_in_index_1] <= `ICDC2015_DS  index_arr[i];
//
//
//        end      
//
//
//    end
    else if(sort_period)
    begin

        if( color_arr[i] < color_arr [image_in_index_1-5'd1] )
        begin

        end
       
        else if ( ( avg_arr[i] < avg_arr[image_in_index_1-5'd1] ) && ( color_arr[i] ==color_arr [image_in_index_1-5'd1] )  )
        begin

        end    

        else
        begin


            color_arr[i]  <= `ICDC2015_DS  color_arr[image_in_index_1-1];
            avg_arr[i]    <= `ICDC2015_DS  avg_arr[image_in_index_1-1]  ;
            index_arr[i]  <= `ICDC2015_DS  index_arr[image_in_index_1-1];


            color_arr[image_in_index_1-1] <= `ICDC2015_DS  color_arr[i];
            avg_arr[image_in_index_1-1]   <= `ICDC2015_DS  avg_arr[i]  ;
            index_arr[image_in_index_1-1] <= `ICDC2015_DS  index_arr[i];


        end      


    end








end



always @(posedge clk or posedge reset)
begin
   if (reset)
   begin
       r_cnt               <= `ICDC2015_DS 14'd0;
       g_cnt               <= `ICDC2015_DS 14'd0;
       b_cnt               <= `ICDC2015_DS 14'd0;
       r_sum               <= `ICDC2015_DS 22'd0;
       g_sum               <= `ICDC2015_DS 22'd0;
       b_sum               <= `ICDC2015_DS 22'd0;
       pixel_cnt           <= `ICDC2015_DS 14'd0;
       busy                <= `ICDC2015_DS  1'd0;
       busy_keep                <= `ICDC2015_DS  1'd0;
       image               <= `ICDC2015_DS  2'd3;
       image_avg           <= `ICDC2015_DS 16'd0;
       i                   <= `ICDC2015_DS  5'd0;
       sort_period         <= `ICDC2015_DS  1'd0;
       sort_end            <= `ICDC2015_DS  1'd0;
       final_sort_end            <= `ICDC2015_DS  1'b0;
       color_index             <= `ICDC2015_DS  2'd0;
       image_out_index         <= `ICDC2015_DS  5'd0;
       image_in_index_keep     <= `ICDC2015_DS  1'd0;
        out_valid              <= `ICDC2015_DS  1'd0;
        out_cnt              <= `ICDC2015_DS  1'd0;
   end
   else
   begin

       r_cnt               <= `ICDC2015_DS r_cnt_pre;
       g_cnt               <= `ICDC2015_DS g_cnt_pre;
       b_cnt               <= `ICDC2015_DS b_cnt_pre;
       r_sum               <= `ICDC2015_DS r_sum_pre;
       g_sum               <= `ICDC2015_DS g_sum_pre;
       b_sum               <= `ICDC2015_DS b_sum_pre;
       pixel_cnt           <= `ICDC2015_DS pixel_cnt_pre;
       busy                <= `ICDC2015_DS busy_pre;
       busy_keep                <= `ICDC2015_DS busy_keep_pre;
       image               <= `ICDC2015_DS image_pre;
       image_avg           <= `ICDC2015_DS image_avg_pre;
       i                   <= `ICDC2015_DS i_pre;
       sort_period         <= `ICDC2015_DS  sort_period_pre;
       sort_end            <= `ICDC2015_DS  sort_end_pre;
       final_sort_end            <= `ICDC2015_DS  final_sort_end_pre;
        out_valid              <= `ICDC2015_DS  out_valid_pre;
        out_cnt              <= `ICDC2015_DS  out_cnt_pre;
       color_index             <= `ICDC2015_DS  color_index_pre;
       image_out_index         <= `ICDC2015_DS  image_out_index_pre;
       image_in_index_keep     <= `ICDC2015_DS   image_in_index_keep_pre;
   end

end





endmodule