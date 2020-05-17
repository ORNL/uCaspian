/* uCaspian Dendrite Mux
 * Parker Mitchell, 2019
 *
 * Muxes the incoming fires from synapses to a single dendrite unit.
 */

`ifndef uCaspian_Dendrite_Mux_SV
`define uCaspian_Dendrite_Mux_SV

module dendrite_mux(
    input               clk,
    input               reset,
    input               enable,

    input        [7:0]  syn_dend_addr_0,
    input        [7:0]  syn_dend_addr_1,
    input        [7:0]  syn_dend_addr_2,
    input        [7:0]  syn_dend_addr_3,
    input        [7:0]  incoming_addr,

    input        [7:0]  syn_dend_charge_0,
    input        [7:0]  syn_dend_charge_1,
    input        [7:0]  syn_dend_charge_2,
    input        [7:0]  syn_dend_charge_3,
    input        [7:0]  incoming_charge,

    input               syn_dend_vld_0,
    input               syn_dend_vld_1,
    input               syn_dend_vld_2,
    input               syn_dend_vld_3,
    input               incoming_vld,

    output logic        syn_dend_rdy_0,
    output logic        syn_dend_rdy_1,
    output logic        syn_dend_rdy_2,
    output logic        syn_dend_rdy_3,
    output logic        incoming_rdy,
    
    output logic [7:0]  dend_addr,
    output logic signed [8:0] dend_charge,
    output logic        dend_vld,
    input               dend_rdy
);

localparam [2:0] IN_PORT = 4;
localparam [2:0] RST_PORT = 5;

// TODO

logic syn_rdy [4:0];
logic syn_vld [4:0];

always_comb begin
    syn_dend_rdy_0 = syn_rdy[0];
    syn_dend_rdy_1 = syn_rdy[1];
    syn_dend_rdy_2 = syn_rdy[2];
    syn_dend_rdy_3 = syn_rdy[3];
    incoming_rdy   = syn_rdy[IN_PORT];
    
    syn_vld[0] = syn_dend_vld_0;
    syn_vld[1] = syn_dend_vld_1;
    syn_vld[2] = syn_dend_vld_2;
    syn_vld[3] = syn_dend_vld_3;
    syn_vld[IN_PORT] = incoming_vld;
end

logic [2:0] syn_select;

/*
always_ff @(posedge clk) begin
    if(reset) begin
        syn_select <= RST_PORT;
    end
    else begin
        if(syn_vld[IN_PORT])
            syn_select <= IN_PORT;
        else if(syn_vld[0])
            syn_select <= 0;
        else if(syn_vld[1])
            syn_select <= 1;
        else if(syn_vld[2])
            syn_select <= 2;
        else if(syn_vld[3])
            syn_select <= 3;
        else
            syn_select <= 0;
    end
end
*/

always_comb begin
    syn_rdy[0] = 0;
    syn_rdy[1] = 0;
    syn_rdy[2] = 0;
    syn_rdy[3] = 0;
    syn_rdy[4] = 0;

    if(reset) begin
        syn_select = RST_PORT;
    end
    else begin
        if(syn_vld[IN_PORT])
            syn_select = IN_PORT;
        else if(syn_vld[0])
            syn_select = 0;
        else if(syn_vld[1])
            syn_select = 1;
        else if(syn_vld[2])
            syn_select = 2;
        else if(syn_vld[3])
            syn_select = 3;
        else
            syn_select = 0;
    end

    case(syn_select)
        0: begin
            dend_addr   = syn_dend_addr_0;
            // sign extend to 9 bits
            dend_charge = $signed({syn_dend_charge_0[7], syn_dend_charge_0});
            dend_vld    = syn_vld[0];
            syn_rdy[0]  = dend_rdy;
        end
        1: begin
            dend_addr   = syn_dend_addr_1;
            dend_charge = $signed({syn_dend_charge_1[7], syn_dend_charge_1});
            dend_vld    = syn_vld[1];
            syn_rdy[1]  = dend_rdy;
        end
        2: begin
            dend_addr   = syn_dend_addr_2;
            dend_charge = $signed({syn_dend_charge_2[7], syn_dend_charge_2});
            dend_vld    = syn_vld[2];
            syn_rdy[2]  = dend_rdy;
        end
        3: begin
            dend_addr   = syn_dend_addr_3;
            dend_charge = $signed({syn_dend_charge_3[7], syn_dend_charge_3});
            dend_vld    = syn_vld[3];
            syn_rdy[3]  = dend_rdy;
        end
        IN_PORT: begin
            dend_addr   = incoming_addr;
            dend_charge = $signed({1'b0, incoming_charge});
            dend_vld    = syn_vld[IN_PORT];
            syn_rdy[IN_PORT] = dend_rdy;
        end
        default: begin
            dend_addr = 0;
            dend_charge = 0;
            dend_vld = 0;
        end
    endcase
end

endmodule

`endif
