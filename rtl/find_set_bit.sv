/* uCaspian Find Set Bit
 * Parker Mitchell, 2019
 *
 * This module finds the first set bit in a bitfield. This is 
 * useful for how uCaspian handles certain activity-driven computation.
 */
`ifndef uCaspian_Find_Set_Bit_16_SV
`define uCaspian_Find_Set_Bit_16_SV


/* find first set bit (8 -> 3 priority encoder)
 * 
 * Finds index of the first '1' in a 8 bit value.
 */
/*
module find_set_bit_8(
    input        [7:0] in,
    output logic [2:0]  out,
    output logic        none_found
);

always_comb begin
    none_found = 0;
    if(in[7])       out =  7;
    else if(in[6])  out =  6;
    else if(in[5])  out =  5;
    else if(in[4])  out =  4;
    else if(in[3])  out =  3;
    else if(in[2])  out =  2;
    else if(in[1])  out =  1;
    else if(in[0])  out =  0;
    else begin
        out = 0;
        none_found = 1;
    end
end

endmodule
*/

/* find first set bit (16 -> 4 priority encoder)
 * 
 * Finds index of the first '1' in a 16 bit value.
 * This was previously parameterized, but yosys didn't like it.
 */
module find_set_bit_16(
    input        [15:0] in,
    output logic [3:0]  out,
    output logic        none_found
);

always_comb begin
    none_found = 0;

    if(in[0])  out =  0;
    else if(in[1])  out =  1;
    else if(in[2])  out =  2;
    else if(in[3])  out =  3;
    else if(in[4])  out =  4;
    else if(in[5])  out =  5;
    else if(in[6])  out =  6;
    else if(in[7])  out =  7;
    else if(in[8])  out =  8;
    else if(in[9])  out =  9;
    else if(in[10]) out = 10;
    else if(in[11]) out = 11;
    else if(in[12]) out = 12;
    else if(in[13]) out = 13;
    else if(in[14]) out = 14;
    else if(in[15]) out = 15;
    else begin
        out = 0;
        none_found = 1;
    end

    /*
    if(in[15]) out = 15;
    else if(in[14]) out = 14;
    else if(in[13]) out = 13;
    else if(in[12]) out = 12;
    else if(in[11]) out = 11;
    else if(in[10]) out = 10;
    else if(in[9])  out =  9;
    else if(in[8])  out =  8;
    else if(in[7])  out =  7;
    else if(in[6])  out =  6;
    else if(in[5])  out =  5;
    else if(in[4])  out =  4;
    else if(in[3])  out =  3;
    else if(in[2])  out =  2;
    else if(in[1])  out =  1;
    else if(in[0])  out =  0;
    else begin
        out = 0;
        none_found = 1;
    end
    */
end

endmodule

/* find first set bit (32 -> 5 priority encoder)
 * 
 * Finds index of the first '1' in a 32 bit value.
 * This was previously parameterized, but yosys didn't like it.
 */
/*
module find_set_bit_32(
    input        [31:0] in,
    output logic [4:0]  out,
    output logic        none_found
);

always_comb begin
    none_found = 0;
    if(in[31]) out = 31;
    else if(in[30]) out = 30;
    else if(in[29]) out = 29;
    else if(in[28]) out = 28;
    else if(in[27]) out = 27;
    else if(in[26]) out = 26;
    else if(in[25]) out = 25;
    else if(in[24]) out = 24;
    else if(in[23]) out = 23;
    else if(in[22]) out = 22;
    else if(in[21]) out = 21;
    else if(in[20]) out = 20;
    else if(in[19]) out = 19;
    else if(in[18]) out = 18;
    else if(in[17]) out = 17;
    else if(in[16]) out = 16;
    else if(in[15]) out = 15;
    else if(in[14]) out = 14;
    else if(in[13]) out = 13;
    else if(in[12]) out = 12;
    else if(in[11]) out = 11;
    else if(in[10]) out = 10;
    else if(in[9])  out =  9;
    else if(in[8])  out =  8;
    else if(in[7])  out =  7;
    else if(in[6])  out =  6;
    else if(in[5])  out =  5;
    else if(in[4])  out =  4;
    else if(in[3])  out =  3;
    else if(in[2])  out =  2;
    else if(in[1])  out =  1;
    else if(in[0])  out =  0;
    else begin
        out = 0;
        none_found = 1;
    end
end

endmodule
*/
`endif
