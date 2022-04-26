module sm4_encrypt
(
    input clk,
    input rst,
    input [127:0] data,
    input [127:0] key,
    output [127:0] cypher
);

localparam FK0	=	32'ha3b1bac6;
localparam FK1	=	32'h56aa3350;
localparam FK2	=	32'h677d9197;
localparam FK3	=	32'hb27022dc;

logic [31:0] K [35:0][32:0];
logic [31:0] D [3:0];
logic [31:0] MK [3:0];
logic [31:0] X [35:0][32:0];

logic [31:0] tau_rk[31:0];
logic [31:0] tau[31:0];
logic [31:0] cki [31:0];
logic [31:0] cki_r [31:0];

assign MK[3] = key[31:0];
assign MK[2] = key[63:32];
assign MK[1] = key[95:64];
assign MK[0] = key[127:96];

assign K[0][0] = MK[0] ^ FK0;
assign K[1][0] = MK[1] ^ FK1;
assign K[2][0] = MK[2] ^ FK2;
assign K[3][0] = MK[3] ^ FK3;

assign D[3] = data[31:0];
assign D[2] = data[63:32];
assign D[1] = data[95:64];
assign D[0] = data[127:96];

assign X[0][0] = D[0];
assign X[1][0] = D[1];
assign X[2][0] = D[2];
assign X[3][0] = D[3];


genvar i;
generate
    for(i = 0; i < 32; i=i+1)
    begin : rounds
        get_cki ck(i,cki[i]);
        enc_round r0 (K[i][i], K[i+1][i], K[i+2][i],K[i+3][i], cki[i],X[i][i], X[i+1][i], X[i+2][i], X[i+3][i], K[i+4][i], X[i+4][i]);
        integer j;
        always_ff@(posedge clk)
        begin
            for(j = 0; j <= i+4; j = j+1)
            begin
                K[j][i+1] <= K[j][i];
                X[j][i+1] <= X[j][i];
            end
        end
	 
    end
endgenerate

assign cypher[31:0]  = X[32][31];
assign cypher[63:32] = X[33][31];
assign cypher[95:64] = X[34][31];
assign cypher[127:96]= X[35][31];
endmodule

module enc_round
(
    input [31:0] K0,
    input [31:0] K1,
    input [31:0] K2,
    input [31:0] K3,
    input [31:0] CK,

    input [31:0] X0,
    input [31:0] X1,
    input [31:0] X2,
    input [31:0] X3,

    output [31:0] K4,
    output [31:0] X4
);

logic [31:0] tau_rk;
logic [31:0] tau;

logic [31:0] l_tr_rk;
logic [31:0] l_tr;

sbox_32bit sb1(K1 ^ K2 ^ K3 ^ CK, tau_rk);
assign l_tr_rk = tau_rk ^ {tau_rk[18:0],tau_rk[31:19]} ^ {tau_rk[8:0],tau_rk[31:9]};
assign K4 = K0 ^ l_tr_rk;

sbox_32bit sb2(X1 ^ X2 ^ X3 ^ K4, tau);
assign l_tr = tau ^ {tau[29:0],tau[31:30]} ^ {tau[21:0],tau[31:22]} ^ {tau[13:0],tau[31:14]} ^ {tau[7:0],tau[31:8]};
assign X4 = X0 ^ l_tr;

endmodule
