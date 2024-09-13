//
// t9990_pattern.sv
//
// BSD 3-Clause License
// 
// Copyright (c) 2024, Shinobu Hashimoto
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
// 
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

`default_nettype none
//`define T9990_PATTERN_BUFFER_USE_DPB

/***************************************************************
 * P1/P2 画面生成
 ***************************************************************/
module T9990_PATTERN #(
    parameter IS_B = 0,
    parameter PAT_ADDR = 19'h00000,
    parameter NAME_ADDR = 19'h7C000
) (
    input wire              RESET_n,
    input wire              CLK,
    input wire              DCLK_EN,
    input wire              DISABLE,

    T9990_REGISTER_IF.VDP   REG,
    input wire [10:0]       SCX,
    input wire [12:0]       SCY,

    input wire [9:0]        HCNT,
    input wire [8:0]        VCNT,
    input wire              START,

    T9990_VDP_MEM_IF.VDP    MEM,

    output wire [5:0]       PA,
    output wire [1:0]       PRI
);
    /***************************************************************
     * P2 モードフラグ
     ***************************************************************/
    wire P2 = REG.DSPM[0];

    /***************************************************************
     * 信号の生成
     ***************************************************************/
    logic [$bits(PA)-1:0]  PA_GEN;
    logic [$bits(PRI)-1:0] PRI_GEN;

    wire [10:0] x = P2 ? {SCX[10:5], 5'b00000} : {SCX[10:4], 4'b0000};

    TINY9990_PATTERN_GEN #(
        .IS_B(IS_B),
        .PAT_ADDR(PAT_ADDR),
        .NAME_ADDR(NAME_ADDR)
    ) u_gen (
        .RESET_n,
        .CLK,
        .DCLK_EN,
        .DISABLE,

        .REG,
        .P2,
        .X(x + HCNT),
        .Y(SCY+VCNT),

        .HCNT,
        .VCNT,
        .START,

        .MEM,

        .PA(PA_GEN),
        .PRI(PRI_GEN)
    );

    /***************************************************************
     * 水平方向シフト
     ***************************************************************/
    logic [$bits(PRI_GEN)+$bits(PA_GEN)-1:0] OUT;

    T9990_SHIFT_BUFFER #(
        .BIT_WIDTH($bits(OUT)),
        .COUNT(32)
    ) u_sht_buf (
        .RESET_n,
        .CLK,
        .DCLK_EN,
        .DISABLE,
        .OFFSET(P2 ? SCX[4:0] : {1'b1, SCX[3:0]}),
        .IN({PRI_GEN, PA_GEN}),
        .OUT
    );

    assign PA = OUT[$bits(PA_GEN)-1:0];
    assign PRI = OUT[$bits(PRI_GEN)+$bits(PA_GEN)-1:$bits(PA_GEN)];

endmodule

module TINY9990_PATTERN_GEN #(
    parameter IS_B = 0,
    parameter PAT_ADDR = 19'h00000,
    parameter NAME_ADDR = 19'h7C000
) (
    input wire              RESET_n,
    input wire              CLK,
    input wire              DCLK_EN,
    input wire              DISABLE,

    T9990_REGISTER_IF.VDP   REG,
    input wire              P2,
    input wire [10:0]       X,
    input wire [12:0]       Y,

    input wire [9:0]        HCNT,
    input wire [8:0]        VCNT,
    input wire              START,

    T9990_VDP_MEM_IF.VDP    MEM,

    output reg [5:0]        PA,
    output reg [1:0]        PRI
);

    enum logic [3:0] {
        STATE_NAME_0_1,
        STATE_NAME_2_3,
        STATE_PAT_0,
        STATE_PAT_1,
        STATE_PAT_2,
        STATE_PAT_3
    } state;

    /***************************************************************
     * VRAM 読み出しデータ処理
     ***************************************************************/
    logic [18:0] pat_0_addr;
    logic [18:0] pat_1_addr;
    logic [18:0] pat_2_addr;
    logic [18:0] pat_3_addr;
    logic [31:0] pat_0_buff;
    logic [31:0] pat_1_buff;
    logic [31:0] pat_2_buff;
    logic [31:0] pat_3_buff;

    wire [12:0] P1_0 = MEM.DOUT[12: 0];
    wire [12:0] P1_1 = MEM.DOUT[28:16];
    wire [13:0] P2_0 = MEM.DOUT[13: 0];
    wire [13:0] P2_1 = MEM.DOUT[29:16];

    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n) begin
            //pat_0_buff <= 0;
            //pat_1_buff <= 0;
            //pat_2_buff <= 0;
            //pat_3_buff <= 0;

            //pat_0_addr <= 0;
            //pat_1_addr <= 0;
            //pat_2_addr <= 0;
            //pat_3_addr <= 0;
        end
        else if(DISABLE) begin
        end
        else if(START) begin
            //pat_0_buff <= 0;
            //pat_1_buff <= 0;
            //pat_2_buff <= 0;
            //pat_3_buff <= 0;
        end
        else if(MEM.ACK) begin
            case (state)
                STATE_NAME_0_1:
                begin
                    if(P2) begin
                        pat_0_addr <= {P2_0[13:6], Y[2:0], P2_0[5:0], 2'b00};
                        pat_1_addr <= {P2_1[13:6], Y[2:0], P2_1[5:0], 2'b00};
                    end
                    else begin
                        pat_0_addr <= {PAT_ADDR[18], P1_0[12:5], Y[2:0], P1_0[4:0], 2'b00};
                        pat_1_addr <= {PAT_ADDR[18], P1_1[12:5], Y[2:0], P1_1[4:0], 2'b00};
                    end
                end
                STATE_NAME_2_3:
                begin
                    if(P2) begin
                        pat_2_addr <= {P2_0[13:6], Y[2:0], P2_0[5:0], 2'b00};
                        pat_3_addr <= {P2_1[13:6], Y[2:0], P2_1[5:0], 2'b00};
                    end
                    else begin
                        // P1 モードで pat_2_addr と pat_3_addr は設定されないけど、とりあえず実装しておく
                        pat_2_addr <= {PAT_ADDR[18], P1_0[12:5], Y[2:0], P1_0[4:0], 2'b00};
                        pat_3_addr <= {PAT_ADDR[18], P1_1[12:5], Y[2:0], P1_1[4:0], 2'b00};
                    end
                end
                STATE_PAT_0:
                begin
                    pat_0_buff <= { MEM.DOUT[ 7: 0], MEM.DOUT[15: 8], MEM.DOUT[23:16], MEM.DOUT[31:24]};
                end
                STATE_PAT_1:
                begin
                    pat_1_buff <= { MEM.DOUT[ 7: 0], MEM.DOUT[15: 8], MEM.DOUT[23:16], MEM.DOUT[31:24]};
                end
                STATE_PAT_2:
                begin
                    pat_2_buff <= { MEM.DOUT[ 7: 0], MEM.DOUT[15: 8], MEM.DOUT[23:16], MEM.DOUT[31:24]};
                end
                STATE_PAT_3:
                begin
                    pat_3_buff <= { MEM.DOUT[ 7: 0], MEM.DOUT[15: 8], MEM.DOUT[23:16], MEM.DOUT[31:24]};
                end
            endcase
        end
    end

    /***************************************************************
     * VRAM アドレス設定
     ***************************************************************/
    wire [18:0] NAME_0_1_ADDR_P1 = {NAME_ADDR[18:13], Y[8:3], X[8:4], 2'b00};
    wire [18:0] NAME_0_1_ADDR_P2 = {NAME_ADDR[18:14], Y[8:3], X[9:5], 3'b000};
    wire [18:0] NAME_2_3_ADDR_P2 = {NAME_ADDR[18:14], Y[8:3], X[9:5], 3'b100};

    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n) begin
            MEM.ADDR <= 0;
        end
        else if(DISABLE) begin
        end
        else if(MEM.REQ) begin
            case (state)
                STATE_NAME_0_1: MEM.ADDR <= P2 ? NAME_0_1_ADDR_P2 : NAME_0_1_ADDR_P1;
                STATE_NAME_2_3: MEM.ADDR <= NAME_2_3_ADDR_P2;
                STATE_PAT_0:    MEM.ADDR <= pat_0_addr;
                STATE_PAT_1:    MEM.ADDR <= pat_1_addr;
                STATE_PAT_2:    MEM.ADDR <= pat_2_addr;
                STATE_PAT_3:    MEM.ADDR <= pat_3_addr;
            endcase
        end
    end

    /***************************************************************
     * 次のステート
     ***************************************************************/
    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n) begin
            state <= STATE_NAME_0_1;
        end
        else if(DISABLE) begin
        end
        else if(START) begin
            state <= STATE_NAME_0_1;
        end
        else if(MEM.ACK) begin
            case (state)
                STATE_NAME_0_1: state <= P2 ? STATE_NAME_2_3 : STATE_PAT_0;
                STATE_NAME_2_3: state <=      STATE_PAT_0;
                STATE_PAT_0:    state <=      STATE_PAT_1;
                STATE_PAT_1:    state <= P2 ? STATE_PAT_2 : STATE_NAME_0_1;
                STATE_PAT_2:    state <=      STATE_PAT_3;
                STATE_PAT_3:    state <=      STATE_NAME_0_1;
            endcase
        end
    end

    /***************************************************************
     * ドット出力
     ***************************************************************/
`ifdef T9990_PATTERN_BUFFER_USE_DPB
    wire [127:0] pattern_out;
    wire [127:0] pattern_in = START                          ? 0 :
                              ( P2 && HCNT[4:0] == 5'b11111) ? { pat_0_buff, pat_1_buff, pat_2_buff, pat_3_buff } :
                              (!P2 && HCNT[3:0] == 4'b1111)  ? { pat_0_buff, pat_1_buff, pat_2_buff, pat_3_buff } :
                                                               { pattern_out[123:0], 4'b0000};
    wire pattern_wen = !RESET_n ? 0 :
                       DISABLE  ? 0 :
                       START    ? 1 :
                       DCLK_EN  ? 1 :
                                  0;

    T9990_PATTERN_BUFFER u_buff (
        .CLK,
        .WEN(pattern_wen),
        .IN(pattern_in),
        .OUT(pattern_out)
    );

    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n)                           PA <= 0;
        else if(!DISABLE && !START && DCLK_EN) PA <= {
                                                        (IS_B ? REG.PLT[3:2] : REG.PLT[1:0]),   // ToDo: P2モードの時に X 座標でパレットを変える(PAとPBを交互に動作)
                                                        pattern_out[127:124]
                                                    };
    end

    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n)                           PRI <= 2'b01;
        else if(!DISABLE && !START && DCLK_EN) PRI <= {
                                                        (HCNT[9:6] > (REG.PRX == 0 ? 4'd4 : REG.PRX)) || (VCNT[8:6] > (REG.PRY == 0 ? 3'd4 : REG.PRY)) ^ IS_B,
                                                        (pattern_out[127:124] == 0)
                                                    };
    end
`else
    logic [127:0] pattern;
    always_ff @(posedge CLK or negedge RESET_n) begin
        if(!RESET_n) begin
            //pattern <= 0;
            //PA <= 0;
            //PRI <= 2'b01;
        end
        else if(DISABLE) begin
        end
        else if(START) begin
            //pattern <= 0;
        end
        else if(DCLK_EN) begin
            // 出力
            PA <= {(IS_B ? REG.PLT[3:2] : REG.PLT[1:0]), pattern[127:124]};   // ToDo: P2モードの時に X 座標でパレットを変える(PAとPBを交互に動作)
            PRI[1] <= (HCNT[9:6] > (REG.PRX == 0 ? 4'd4 : REG.PRX)) || (VCNT[8:6] > (REG.PRY == 0 ? 3'd4 : REG.PRY)) ^ IS_B;
            PRI[0] <= (pattern[127:124] == 0);

            // 次のパターンを準備
            if(P2 && HCNT[4:0] == 5'b11111) begin
                pattern <= { pat_0_buff, pat_1_buff, pat_2_buff, pat_3_buff };
            end
            else if(!P2 && HCNT[3:0] == 4'b1111) begin
                pattern <= { pat_0_buff, pat_1_buff, pat_2_buff, pat_3_buff };
            end
            else begin
                pattern <= { pattern[123:0], 4'b0000};
            end
        end
    end
`endif
endmodule

`ifdef T9990_PATTERN_BUFFER_USE_DPB

module T9990_PATTERN_BUFFER (
    input wire          CLK,
    input wire          WEN,
    input wire [127:0]  IN,
    output wire [127:0] OUT
);

    DPB dpb_inst_0 (
        .DOA(),
        .DOB(OUT[15:0]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[15:0]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_0.READ_MODE0 = 1'b0;
    defparam dpb_inst_0.READ_MODE1 = 1'b0;
    defparam dpb_inst_0.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_0.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_0.BIT_WIDTH_0 = 16;
    defparam dpb_inst_0.BIT_WIDTH_1 = 16;
    defparam dpb_inst_0.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_0.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_0.RESET_MODE = "SYNC";

    DPB dpb_inst_1 (
        .DOA(),
        .DOB(OUT[31:16]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[31:16]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_1.READ_MODE0 = 1'b0;
    defparam dpb_inst_1.READ_MODE1 = 1'b0;
    defparam dpb_inst_1.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_1.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_1.BIT_WIDTH_0 = 16;
    defparam dpb_inst_1.BIT_WIDTH_1 = 16;
    defparam dpb_inst_1.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_1.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_1.RESET_MODE = "SYNC";

    DPB dpb_inst_2 (
        .DOA(),
        .DOB(OUT[47:32]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[47:32]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_2.READ_MODE0 = 1'b0;
    defparam dpb_inst_2.READ_MODE1 = 1'b0;
    defparam dpb_inst_2.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_2.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_2.BIT_WIDTH_0 = 16;
    defparam dpb_inst_2.BIT_WIDTH_1 = 16;
    defparam dpb_inst_2.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_2.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_2.RESET_MODE = "SYNC";

    DPB dpb_inst_3 (
        .DOA(),
        .DOB(OUT[63:48]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[63:48]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_3.READ_MODE0 = 1'b0;
    defparam dpb_inst_3.READ_MODE1 = 1'b0;
    defparam dpb_inst_3.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_3.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_3.BIT_WIDTH_0 = 16;
    defparam dpb_inst_3.BIT_WIDTH_1 = 16;
    defparam dpb_inst_3.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_3.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_3.RESET_MODE = "SYNC";

    DPB dpb_inst_4 (
        .DOA(),
        .DOB(OUT[79:64]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[79:64]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_4.READ_MODE0 = 1'b0;
    defparam dpb_inst_4.READ_MODE1 = 1'b0;
    defparam dpb_inst_4.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_4.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_4.BIT_WIDTH_0 = 16;
    defparam dpb_inst_4.BIT_WIDTH_1 = 16;
    defparam dpb_inst_4.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_4.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_4.RESET_MODE = "SYNC";

    DPB dpb_inst_5 (
        .DOA(),
        .DOB(OUT[95:80]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[95:80]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_5.READ_MODE0 = 1'b0;
    defparam dpb_inst_5.READ_MODE1 = 1'b0;
    defparam dpb_inst_5.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_5.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_5.BIT_WIDTH_0 = 16;
    defparam dpb_inst_5.BIT_WIDTH_1 = 16;
    defparam dpb_inst_5.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_5.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_5.RESET_MODE = "SYNC";

    DPB dpb_inst_6 (
        .DOA(),
        .DOB(OUT[111:96]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[111:96]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_6.READ_MODE0 = 1'b0;
    defparam dpb_inst_6.READ_MODE1 = 1'b0;
    defparam dpb_inst_6.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_6.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_6.BIT_WIDTH_0 = 16;
    defparam dpb_inst_6.BIT_WIDTH_1 = 16;
    defparam dpb_inst_6.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_6.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_6.RESET_MODE = "SYNC";

    DPB dpb_inst_7 (
        .DOA(),
        .DOB(OUT[127:112]),
        .CLKA(CLK),
        .OCEA(1'b1),
        .CEA(1'b1),
        .RESETA(1'b0),
        .WREA(WEN),
        .CLKB(CLK),
        .OCEB(1'b1),
        .CEB(1'b1),
        .RESETB(1'b0),
        .WREB(1'b0),
        .BLKSELA({1'b0,1'b0,1'b0}),
        .BLKSELB({1'b0,1'b0,1'b0}),
        .ADA({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIA(IN[127:112]),
        .ADB({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b1}),
        .DIB(16'd0)
    );

    defparam dpb_inst_7.READ_MODE0 = 1'b0;
    defparam dpb_inst_7.READ_MODE1 = 1'b0;
    defparam dpb_inst_7.WRITE_MODE0 = 2'b00;
    defparam dpb_inst_7.WRITE_MODE1 = 2'b00;
    defparam dpb_inst_7.BIT_WIDTH_0 = 16;
    defparam dpb_inst_7.BIT_WIDTH_1 = 16;
    defparam dpb_inst_7.BLK_SEL_0 = 3'b000;
    defparam dpb_inst_7.BLK_SEL_1 = 3'b000;
    defparam dpb_inst_7.RESET_MODE = "SYNC";
endmodule

`endif

`default_nettype wire
