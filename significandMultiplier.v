module significandMultiplier(aIn, bIn, sum, carry);
  `include "parameters.v"
  input [SIG_WIDTH:0] aIn,bIn;
  output [2*(SIG_WIDTH+1)+4:0] sum, carry; //111 
  
  //radix-2 Booth multiples generation
  wire [SIG_WIDTH+2:0] b, twob, minusb, minusTwob;
  assign b = {2'b0,bIn};
  assign minusb = ~{2'b0,bIn} + 1'b1;
  assign twob = {2'b0,bIn}<<1;
  assign minusTwob = minusb<<1;
  
  wire [SIG_WIDTH+3:0] aIn_zeroLSB = {2'b0,aIn,1'b0};
  wire [SIG_WIDTH+2:0] recoded [((SIG_WIDTH+1)/2):0];
  //generate partial products
  genvar i;
  generate
    for(i=1;i<=SIG_WIDTH+2;i=i+2) begin: gen_pp
       modifiedBoothRecoder MBR(aIn_zeroLSB[i-1], aIn_zeroLSB[i], aIn_zeroLSB[i+1], b, twob, minusTwob, minusb, recoded[i>>1]);
    end
  endgenerate
  
  //Multiplier carry-out detection
  wire [(SIG_WIDTH+1)/2:0] pp_signs;
  genvar c;
  generate
    for(c=0;c<(SIG_WIDTH+1)/2+1;c=c+1) begin
       assign pp_signs[c] = recoded[c][SIG_WIDTH+2];
    end
  endgenerate
  wire pp_carry_out = |pp_signs;
  
 
  //CSA array to add partial products (Double Precision tree)
  //SIG_WIDTH=52, recoded_bit_width=55
  wire [SIG_WIDTH+6:0] s_a, s_b, s_c, s_d, 
                       s_e, s_f, s_g, s_h, s_i,
                       c_a, c_b, c_c, c_d,
                       c_e, c_f, c_g, c_h, c_i;//59-bit

  wire [SIG_WIDTH+58:0] s_final, c_final;//111-bit
  
  //Output assignments
  assign sum = s_final; assign carry = c_final;

  
  //Stage 0 (each recoded word is 26-bit)
  //55-bit inputs 59-bit outputs
  
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_a({{4{recoded[0][SIG_WIDTH+2]}},recoded[0]}, 
                              {{2{recoded[1][SIG_WIDTH+2]}},recoded[1],2'b0}, 
                                {recoded[2],4'b0}, s_a, c_a);
                  
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_b({{4{recoded[3][SIG_WIDTH+2]}},recoded[3]}, 
                              {{2{recoded[4][SIG_WIDTH+2]}},recoded[4],2'b0}, 
                                {recoded[5],4'b0}, s_b, c_b);
                                
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_c({{4{recoded[6][SIG_WIDTH+2]}},recoded[6]}, 
                              {{2{recoded[7][SIG_WIDTH+2]}},recoded[7],2'b0}, 
                                {recoded[8],4'b0}, s_c, c_c);
                                
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_d({{4{recoded[9][SIG_WIDTH+2]}},recoded[9]}, 
                              {{2{recoded[10][SIG_WIDTH+2]}},recoded[10],2'b0}, 
                              {recoded[11],4'b0}, s_d, c_d);
  
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_e({{4{recoded[12][SIG_WIDTH+2]}},recoded[12]}, 
                              {{2{recoded[13][SIG_WIDTH+2]}},recoded[13],2'b0}, 
                                {recoded[14],4'b0}, s_e, c_e);
                  
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_f({{4{recoded[15][SIG_WIDTH+2]}},recoded[15]}, 
                              {{2{recoded[16][SIG_WIDTH+2]}},recoded[16],2'b0}, 
                                {recoded[17],4'b0}, s_f, c_f);
                                
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_g({{4{recoded[18][SIG_WIDTH+2]}},recoded[18]}, 
                              {{2{recoded[19][SIG_WIDTH+2]}},recoded[19],2'b0}, 
                                {recoded[20],4'b0}, s_g, c_g);
                                
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_h({{4{recoded[21][SIG_WIDTH+2]}},recoded[21]}, 
                              {{2{recoded[22][SIG_WIDTH+2]}},recoded[22],2'b0}, 
                              {recoded[23],4'b0}, s_h, c_h);
       
  compressor_3_2_group #(.GRP_WIDTH(59)) comp_i({{4{recoded[24][SIG_WIDTH+2]}},recoded[24]}, 
                              {{2{recoded[25][SIG_WIDTH+2]}},recoded[25],2'b0}, 
                              {recoded[26],4'b0}, s_i, c_i);                             
                              

  //Stage 1 (sign-extend sum and carry vectors with to adjust for the increased bit-width)
  //59-bit inputs, 65-bit outputs
 
  //Stage-1 CSA inputs, extended
  wire [SIG_WIDTH+12:0] s_a_ext, c_a_ext, s_b_ext, //inputs to CSA j
                        c_b_ext, s_c_ext, c_c_ext, //inputs to CSA k
                        s_d_ext, c_d_ext, s_e_ext, //inputs to CSA l
                        c_e_ext, s_f_ext, c_f_ext, //inputs to CSA m
                        s_g_ext, c_g_ext, s_h_ext, //inputs to CSA n
                        c_h_ext, s_i_ext, c_i_ext; //inputs to CSA o  
  //Stage-1 CSA outputs
  wire [SIG_WIDTH+12:0] s_j, c_j, s_k, c_k,//65-bit
                      s_l, c_l, s_m, c_m,
                      s_n, c_n, s_o, c_o;
  //j
  assign s_a_ext = {{6{s_a[SIG_WIDTH+6]}},s_a};
  assign s_b_ext = {s_b,6'b0};
  assign c_a_ext = {{5{c_a[SIG_WIDTH+6]}},c_a,1'b0};
  //k
  assign s_c_ext = {{1{s_c[SIG_WIDTH+6]}},s_c,5'b0};
  assign c_c_ext = {c_c,6'b0};
  assign c_b_ext = {{6{c_b[SIG_WIDTH+6]}},c_b};
  //l  
  assign s_d_ext = {{6{s_d[SIG_WIDTH+6]}},s_d};
  assign s_e_ext = {s_e,6'b0};
  assign c_d_ext = {{5{c_d[SIG_WIDTH+6]}},c_d,1'b0};
  //m  
  assign s_f_ext = {{1{s_f[SIG_WIDTH+6]}},s_f,5'b0};
  assign c_f_ext = {c_f,6'b0};
  assign c_e_ext = {{6{c_e[SIG_WIDTH+6]}},c_e}; 
  //n  
  assign s_g_ext = {{6{s_g[SIG_WIDTH+6]}},s_g};
  assign s_h_ext = {s_h,6'b0};
  assign c_g_ext = {{5{c_g[SIG_WIDTH+6]}},c_g,1'b0};
  //o
  assign s_i_ext = {{1{s_i[SIG_WIDTH+6]}},s_i,5'b0};
  assign c_i_ext = {c_i,6'b0};
  assign c_h_ext = {{6{c_h[SIG_WIDTH+6]}},c_h}; 
    
  compressor_3_2_group #(.GRP_WIDTH(65)) comp_j(s_a_ext,c_a_ext,s_b_ext, s_j, c_j);
  compressor_3_2_group #(.GRP_WIDTH(65)) comp_k(s_c_ext,c_c_ext,c_b_ext, s_k, c_k);                              

  compressor_3_2_group #(.GRP_WIDTH(65)) comp_l(s_d_ext,s_e_ext,c_d_ext, s_l, c_l);
  compressor_3_2_group #(.GRP_WIDTH(65)) comp_m(s_f_ext,c_f_ext,c_e_ext, s_m, c_m);  
  
  compressor_3_2_group #(.GRP_WIDTH(65)) comp_n(s_g_ext,s_h_ext,c_g_ext, s_n, c_n);
  compressor_3_2_group #(.GRP_WIDTH(65)) comp_o(s_i_ext,c_i_ext,c_h_ext, s_o, c_o);  


  //Stage-2 inputs/outputs
  wire [SIG_WIDTH+19:0] s_j_ext, c_j_ext, s_k_ext, s_p, c_p;//72-bit
  wire [SIG_WIDTH+23:0] s_l_ext, c_l_ext, c_k_ext, s_q, c_q;//76-bit
  wire [SIG_WIDTH+23:0] s_m_ext, c_m_ext, s_n_ext, s_r, c_r;//76-bit
  wire [SIG_WIDTH+19:0] s_o_ext, c_o_ext, c_n_ext, s_s, c_s;//72-bit
  
  //p
  assign s_j_ext = {{7{s_j[SIG_WIDTH+12]}},s_j};
  assign c_j_ext = {{6{c_j[SIG_WIDTH+12]}},c_j,1'b0};
  assign s_k_ext = {s_k,7'b0};
  compressor_3_2_group #(.GRP_WIDTH(72)) comp_p(s_j_ext,c_j_ext,s_k_ext, s_p, c_p);
  
  //q
  assign s_l_ext = {{1{s_l[SIG_WIDTH+12]}},s_l,10'b0};
  assign c_k_ext = {{11{c_k[SIG_WIDTH+12]}},c_k};
  assign c_l_ext = {c_l,11'b0}; 
  compressor_3_2_group #(.GRP_WIDTH(76)) comp_q(s_l_ext,c_l_ext,c_k_ext, s_q, c_q);
  
  //r
  assign s_m_ext = {{11{s_m[SIG_WIDTH+12]}},s_m};
  assign c_m_ext = {{10{c_m[SIG_WIDTH+12]}},c_m,1'b0};
  assign s_n_ext = {s_n,11'b0};
  compressor_3_2_group #(.GRP_WIDTH(76)) comp_r(s_m_ext,c_m_ext,s_n_ext, s_r, c_r);
  
  //s
  assign s_o_ext = {{1{s_o[SIG_WIDTH+12]}},s_o,6'b0};
  assign c_o_ext = {c_o,7'b0};
  assign c_n_ext = {{7{c_n[SIG_WIDTH+12]}},c_n};
  compressor_3_2_group #(.GRP_WIDTH(72)) comp_s(s_o_ext,c_o_ext,c_n_ext, s_s, c_s);
  


  //Stage-3 inputs/outputs (4:2 stage)
  wire [SIG_WIDTH+32:0] s_p_ext, c_p_ext, s_q_ext, c_q_ext, s_u, c_u, cout_u;//85-bit
  wire [SIG_WIDTH+32:0] s_r_ext, c_r_ext, s_s_ext, c_s_ext, s_t, c_t, cout_t;//85-bit

  //u
  assign s_p_ext = {{13{s_p[SIG_WIDTH+19]}},s_p};
  assign c_p_ext = {{12{c_p[SIG_WIDTH+19]}},c_p,1'b0};
  assign s_q_ext = {s_q[SIG_WIDTH+23],s_q,8'b0};
  assign c_q_ext = {c_q,9'b0};
  compressor_4_2_group #(.GRP_WIDTH(85)) comp_u(s_p_ext, c_p_ext, s_q_ext, c_q_ext,
                              {cout_u[83:0],1'b0}, s_u, c_u, cout_u);
  
  //t
  assign s_r_ext = {{9{s_r[SIG_WIDTH+23]}},s_r}; 
  assign c_r_ext = {{8{c_r[SIG_WIDTH+23]}},c_r,1'b0};
  assign s_s_ext = {s_s[SIG_WIDTH+19],s_s,12'b0};
  assign c_s_ext = {c_s,13'b0};
  compressor_4_2_group #(.GRP_WIDTH(85)) comp_t(s_r_ext, c_r_ext, s_s_ext, c_s_ext,
                              {cout_t[83:0],1'b0}, s_t, c_t, cout_t);
   

  //Stage-4 inputs/outputs
  wire [SIG_WIDTH+58:0] s_u_ext, c_u_ext, s_t_ext, c_t_ext, cout_v;
  
  //v
  wire cond = (cout_u[84] ^ s_u[84]) & c_u[84];
  assign s_u_extbits = (cond)?1'b0:s_u[84];//(cout_u[84]~^c_u[84])?1'b1: s_u[84];
  assign s_u_ext = {{26{s_u_extbits}},  s_u};
  assign c_u_ext = {{25{c_u[SIG_WIDTH+32]}}, c_u, 1'b0};
  assign s_t_ext = {s_t[SIG_WIDTH+32],s_t,25'b0};
  assign c_t_ext = {c_t,26'b0};
  compressor_4_2_group #(.GRP_WIDTH(111)) comp_v(s_u_ext, c_u_ext, s_t_ext, c_t_ext,
                              {cout_v[109:0],1'b0}, s_final, c_final, cout_v);
 
endmodule

