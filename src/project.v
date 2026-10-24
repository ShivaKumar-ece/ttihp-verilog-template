`timescale 1ns / 1ps

module accumulator(
    input clk, acc_en, reset,
    input [7:0] acc_in,
    output reg [7:0] acc_out
);

always @(posedge clk) begin
    if (reset) acc_out <= 8'd0;
    else if (acc_en) acc_out <= acc_in;
end

endmodule

module adder(
    input [7:0] pc_out,
    output [7:0] pc_plus_1
);

assign pc_plus_1 = pc_out + 1'b1;

endmodule

module alu(
    input [7:0] acc_out, rd_data,
    input [3:0] alu_ctrl,
    output reg [7:0] acc_in
);

reg c = 1'b0;

always @(*) begin
    case (alu_ctrl)
        4'b1000: {c, acc_in} = acc_out + rd_data;        // ADD
        4'b1001: {c, acc_in} = acc_out - rd_data;        // SUB
        4'b1010: {c, acc_in} = acc_out + rd_data + c;    // ADC (Add with carry)
        4'b1011: {c, acc_in} = acc_out - rd_data - c;    // SBB (Subtract with borrow)
        4'b1100: acc_in = acc_out & rd_data;             // AND
        4'b1101: acc_in = acc_out | rd_data;             // OR
        4'b1110: acc_in = acc_out ^ rd_data;             // XOR
        4'b1111: acc_in = rd_data;                       // LOAD
        4'b0100: acc_in = acc_out << 1'b1;               // Logical Shift Left
        4'b0101: acc_in = acc_out >> 1'b1;               // Logical Shift Right
        4'b0110: acc_in = acc_out <<< 1'b1;              // Arithmetic Shift Left
        4'b0111: acc_in = acc_out >>> 1'b1;              // Arithmetic Shift Right
        default: acc_in = acc_out;                       // default
       
    endcase
end

endmodule

module mux2x1(
    input [7:0] i0, i1,
    input s,
    output [7:0] y
);
assign y = (s ? i1 : i0);
endmodule

module mux4x1(
    input [7:0] i0, i1, i2, i3, 
    input s0, s1,
    output [7:0] y
);

assign y = (s1 ? (s0 ? i3 : i2) : (s0 ? i1 : i0));
endmodule

module pc(
    input clk, pc_en, reset,
    input [7:0] pc_in,
    output reg [7:0] pc_out
);

always @(posedge clk) begin
    if (reset)
        pc_out <= 8'd0;
    else if (pc_en)
        pc_out <= pc_in;
end

endmodule

module memory(
    input clk, wr_en, fetch, small_addr, reset,
    input [3:0] N, 
    input [7:0] rd_addr, wr_addr, wr_data,
    output reg [7:0] rd_data
    
);

integer i;
reg [7:0] mem [511:0];

always @(posedge clk) begin
    if (reset) begin
    // fibonacci
        mem[9'd0] <= 8'b0; // r0
        mem[9'd1] <= 8'b1; // r1
        mem[9'd2] <= 8'b0; // r2 initialise to 0
        mem[9'd3] <= {4'b0,N}; // r3
        mem[9'd4] <= 8'b1 ; // r4 = 1
        for (i = 5; i < 256; i = i + 1) mem[i] <= 8'd0;

        mem[9'd256] <= 8'h70; // load r0 in A
        mem[9'd257] <= 8'h01; // A = A + r1
        mem[9'd258] <= 8'h82; // store A in r2
        mem[9'd259] <= 8'h71; // load r1 in A
        mem[9'd260] <= 8'h80; // store A in r0
        mem[9'd261] <= 8'h72; // load r2 in A
        mem[9'd262] <= 8'h81; // store A in r1
        mem[9'd263] <= 8'h73; // load r3 in A
        mem[9'd264] <= 8'h14; // sub A - r4 = A - 1
        mem[9'd265] <= 8'h83; // store A in r3
        mem[9'd266] <= 8'hd2; // branch if A is 0
        mem[9'd267] <= 8'h0e; // branch address
        mem[9'd268] <= 8'hd3; // branch if A is not 0
        mem[9'd269] <= 8'h00; // to address 256
        mem[9'd270] <= 8'h72; // load r2 to A as it has final value 
        mem[9'd271] <= 8'hff; // exit
    
//        On reset, read first instruction
        rd_data <= mem[9'd256];
        
        // Sum of n numbers
//        mem[9'd0] <= {4'b0,N}; // r0
//        mem[9'd1] <= {4'b0,N}; // r1
//        mem[9'd2] <= 8'd1; // r2
//        for (i = 3; i < 256; i = i + 1) mem[i] <= 8'd0;
        
//        mem[9'd256] <= 8'h71; // load r1 to A
//        mem[9'd257] <= 8'h12; // A = A - r2
//        mem[9'd258] <= 8'h81; // store A in r1
//        mem[9'd259] <= 8'hd2; // branch if A is 0
//        mem[9'd260] <= 8'h09; // branch address
//        mem[9'd261] <= 8'h00; // add A = A + r0
//        mem[9'd262] <= 8'h80; // store A in r0
//        mem[9'd263] <= 8'hd0; // branch
//        mem[9'd264] <= 8'h00; // branch address
//        mem[9'd265] <= 8'h70; // load r0 in A
//        mem[9'd266] <= 8'hff; // exit   
//        rd_data <= mem[9'd256];  
    end 
    
    else begin
        if (fetch) begin
            // Instruction fetch from instruction memory
            rd_data <= mem[{fetch, rd_addr}];
        end else if (small_addr == 1) begin
            if (wr_en) begin
                mem[{fetch, 4'b0000, wr_addr[3:0]}] <= wr_data;
            end else begin
                rd_data <= mem[{fetch, 4'b0000, rd_addr[3:0]}];
            end
        end else begin
            if (wr_en) begin
                mem[{fetch, wr_addr}] <= wr_data;
            end else begin
                rd_data <= mem[{fetch, rd_addr}];
            end
        end
    end
end

endmodule

module ctrl_unit(
    output reg [1:0] mux_pc_rd,      // selection for PC read
    output reg wr_addr,              // Write address signal
    output reg wr_data,              // Write data signal
    output reg pc_en,                // PC enable signal
    output reg acc_en,               // Accumulator enable signal
    output reg fetch,                // Fetch signal
    output reg small_addr,           // Small address signal
    output reg [3:0] alu_ctrl_store, // Store ALU control signal
    output reg [3:0] state,          // Current state
    output reg [3:0] next_state,     // Next state
    input reset,                     // Reset input signal
    input [7:0] A,                   // 8-bit input A
    input [7:0] instruction,         // 8-bit instruction input
    input clk                        // Clock signal
);

reg [3:0] alu_ctrl;

// State definitions 
parameter S0  = 4'd0;
parameter S1  = 4'd1;
parameter S2  = 4'd2;
parameter S3  = 4'd3;
parameter S4  = 4'd4;
parameter S5  = 4'd5;
parameter S6  = 4'd6;
parameter S7  = 4'd7;
parameter S8  = 4'd8;
parameter S9  = 4'd9;
parameter S10 = 4'd10;
parameter S11 = 4'd11;

always @(posedge clk)
begin
    alu_ctrl_store <= alu_ctrl;
end

always @(posedge clk)
begin
    if (reset)
        state <= S0; // Reset the state to S0
    else
        state <= next_state; // Transition to the next state
end

always @(instruction, state)
begin
    if (reset) next_state <= S0;
    else begin 
    case(state)
        S0: begin
            if (instruction[7] == 0)
                next_state = S1; // Transition to S1 if instruction[7] is 0
            else begin
                case(instruction[7:4])
                    4'b1000: next_state = S2;
                    4'b1001: next_state = S3;
                    4'b1010: next_state = S4;
                    4'b1011: next_state = S6;
                    4'b1100: next_state = S8;
                    4'b1101: begin
                        case(instruction[1:0])
                            2'b00: next_state = S9;
                            2'b10: begin
                                if (A == 8'b00) next_state = S9;
                                else next_state = S10;
                            end
                            2'b11: begin
                                if (A == 8'b00) next_state = S10;
                                else next_state = S9;
                            end
                        endcase
                    end
                    4'b1110: next_state = S0;
                    4'b1111: next_state = S11;
                    default: next_state = S0;
                endcase
            end
        end
        
        // States that return to S0
        S1, S2, S3, S5, S7, S8, S9, S10: next_state = S0;
        
        // State S4 transitions to S5
        S4: next_state = S5;
        
        // State S6 transitions to S7
        S6: next_state = S7;
        
        // State S11 stays in S11
        S11: next_state = S11;
        
        // Default case to return to S0
        default: next_state = S0;
    endcase
    end
end

always @(instruction, state)
begin
    case(state)
        // State S0 logic
        S0: if (instruction[7] == 0) begin
            mux_pc_rd = 2'b10;
            wr_addr = 0;
            pc_en = 0; 
            acc_en = 0;
            alu_ctrl = {1'b1, instruction[6:4]};
            fetch = 0;
            small_addr = 1;
        end else begin
            case(instruction[7:4])
                4'b1000: begin
                    wr_addr = 1;
                    wr_data = 0;
                    pc_en = 0; 
                    acc_en = 0;
                    alu_ctrl = 4'b0000;
                    fetch = 0;
                    small_addr = 1;
                end
                4'b1001: begin
                    mux_pc_rd = 2'b01;
                    wr_addr = 1;
                    wr_data = 1;
                    pc_en = 0; 
                    acc_en = 0;
                    fetch = 0;
                    alu_ctrl = 4'b0000;
                    small_addr = 1;
                end
                4'b1010: begin
                    mux_pc_rd = 2'b10;
                    wr_addr = 0;
                    pc_en = 0; 
                    acc_en = 0;
                    fetch = 0;
                    alu_ctrl = 4'b0000;
                    small_addr = 1;
                end
                4'b1011: begin
                    mux_pc_rd = 2'b10;
                    wr_addr = 0;
                    pc_en = 0; 
                    acc_en = 0;
                    fetch = 0;
                    alu_ctrl = 4'b0000;
                    small_addr = 1;
                end
                4'b1100: begin
                    mux_pc_rd = 2'b00;
                    wr_addr = 0;
                    pc_en = 1; 
                    acc_en = 0;
                    fetch = 1;
                    alu_ctrl = {1'b1, instruction[2:0]};
                end
                4'b1101: begin
                    mux_pc_rd = 2'b00;
                    wr_addr = 0;
                    pc_en = 1; 
                    acc_en = 0;
                    fetch = 1;
                    alu_ctrl = 4'b0000;
                end
                4'b1110: begin
                    mux_pc_rd = 2'b00;
                    wr_addr = 0;
                    pc_en = 1; 
                    acc_en = 1;
                    fetch = 1;
                    alu_ctrl = {2'b01, instruction[1:0]};
                end
                4'b1111: begin
                    mux_pc_rd = 2'b10;
                    wr_addr = 0;
                    pc_en = 0; 
                    acc_en = 0;
                    fetch = 1;
                    alu_ctrl = 4'b0000;
                end
                default: begin
                    mux_pc_rd = 2'b11;
                    wr_addr = 0;
                    pc_en = 0;
                    acc_en = 0;
                    alu_ctrl = 4'b0000;
                    fetch = 1;
                end
            endcase
        end
        
        S1: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 1;
            fetch = 1;
        end
        
        S2: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 0;
            fetch = 1;
        end
        
        S3: begin
            mux_pc_rd = 2'b01;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 0;
            fetch = 1;
        end
        
        S4: begin
            mux_pc_rd = 2'b01;
            wr_addr = 0;
            pc_en = 0; 
            acc_en = 0;
            fetch = 0;
            small_addr = 0;
        end
        
        S5: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 1;
            fetch = 1;
        end
        
        S6: begin
            wr_addr = 1;
            wr_data = 0;
            pc_en = 0; 
            acc_en = 0;
            fetch = 0;
            small_addr = 0;
        end
        
        S7: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 0;
            fetch = 1;
        end
        
        S8: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 1;
            fetch = 1;
        end
        
        S9: begin
            mux_pc_rd = 2'b10;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 0;
            fetch = 1;
        end
        
        S10: begin
            mux_pc_rd = 2'b00;
            wr_addr = 0;
            pc_en = 1; 
            acc_en = 0;
            fetch = 1;
        end
        
        // State S11 logic
        S11: begin
            mux_pc_rd = 2'b11;
            wr_addr = 0;
            pc_en = 0;
            acc_en = 0;
            alu_ctrl = 4'b0000;
            fetch = 1;
        end
        
        // Default 
        default: begin
            mux_pc_rd = 2'b11;
            wr_addr = 0;
            pc_en = 0;
            acc_en = 0;
            alu_ctrl = 4'b0000;
            fetch = 1;
        end
    endcase
end

endmodule

module seven_segment(
    output reg [7:0] seg_led,
    output reg [3:0] seg_ctrl,
    input [7:0] q,
    input clk
);
reg [16:0] refresh_counter;
always @(posedge clk) 
begin
    refresh_counter <= refresh_counter + 1;
end

wire [1:0] digit_select = refresh_counter[16:15]; 
reg [3:0] current_digit;
wire [3:0] ones,tens,hundreds,thousands;
assign ones     = q % 10;
assign tens     = (q / 10) % 10;
assign hundreds = q / 100;
assign thousands = 0;
always @(*) begin
    case(digit_select)
        2'b00: begin
            current_digit = ones;
            seg_ctrl = 4'b1110; // enable digit 0
        end
        2'b01: begin
            current_digit = tens;
            seg_ctrl = 4'b1101;
        end
        2'b10: begin
            current_digit = hundreds;
            seg_ctrl = 4'b1011;
        end
        2'b11: begin
            current_digit = thousands;
            seg_ctrl = 4'b0111;
        end
        default: begin
            current_digit = 0;
            seg_ctrl = 4'b1111;
        end
    endcase
end
    
always @(*)
    begin
        case(current_digit)
        4'b0000: seg_led = 8'b10000001; // "0"     
        4'b0001: seg_led = 8'b11001111; // "1" 
        4'b0010: seg_led = 8'b10010010; // "2" 
        4'b0011: seg_led = 8'b10000110; // "3" 
        4'b0100: seg_led = 8'b11001100; // "4" 
        4'b0101: seg_led = 8'b10100100; // "5" 
        4'b0110: seg_led = 8'b10100000; // "6" 
        4'b0111: seg_led = 8'b10001111; // "7" 
        4'b1000: seg_led = 8'b10000000; // "8"     
        4'b1001: seg_led = 8'b10000100; // "9" 
        default: seg_led = 8'b11111111;
        endcase
    end    
    
endmodule

module tt_um_lipsi_processor_shiva(
    input clk, reset,
    input [3:0] N,
    output [7:0] acc,
    output [3:0] seg_ctrl,
    output [7:0] seg_led
);

    // Internal wires
    wire [3:0] state, next_state;
    wire [3:0] alu_ctrl;
    wire [7:0] rd_data;
    wire [7:0] acc_in;
    wire [3:0] alu_ctrl_store;
    wire [1:0] mux_pc_rd;
    wire [7:0] rd_addr, wr_addr, wr_data;
    wire [7:0] pc_in, pc_out, pc_plus_1;
    wire [7:0] acc_out;
    
    assign acc = acc_out;

    wire fetch, small_addr;
    wire mux_wr_addr;
    
    assign wr_en = mux_wr_addr;

    memory m1(
        .clk(clk),
        .N(N), 
        .wr_en(wr_en), 
        .fetch(fetch | reset), 
        .reset(reset),
        .rd_addr(pc_in), 
        .wr_addr(wr_addr), 
        .wr_data(wr_data),
        .rd_data(rd_data), 
        .small_addr(small_addr) 
        
    );

    mux2x1 mux1(
        .i0(8'd0), 
        .i1(rd_data), 
        .y(wr_addr), 
        .s(mux_wr_addr)
    );

    mux2x1 mux2(
        .i0(acc_out), 
        .i1(pc_out), 
        .y(wr_data), 
        .s(mux_wr_data)
    );

    mux4x1 mux3(
        .i0(pc_plus_1), 
        .i1(acc_out), 
        .i2(rd_data), 
        .i3(8'd0),
        .y(pc_in), 
        .s1(mux_pc_rd[1] | reset), 
        .s0(mux_pc_rd[0] | reset)
    );

    pc p1(
        .clk(clk), 
        .pc_en(pc_en), 
        .reset(reset), 
        .pc_in(pc_in), 
        .pc_out(pc_out)
    );

    adder a1(
        .pc_out(pc_out), 
        .pc_plus_1(pc_plus_1)
    );

    accumulator acc1(
        .clk(clk),
        .reset(reset), 
        .acc_en(acc_en), 
        .acc_in(acc_in), 
        .acc_out(acc_out)
    );

    alu alu1(
        .acc_out(acc_out), 
        .rd_data(rd_data), 
        .alu_ctrl(alu_ctrl),
        .acc_in(acc_in)
    );

    ctrl_unit c1(
        .clk(clk), 
        .instruction(rd_data), 
        .alu_ctrl_store(alu_ctrl), 
        .pc_en(pc_en), 
        .reset(reset),
        .acc_en(acc_en), 
        .mux_pc_rd(mux_pc_rd), 
        .wr_addr(mux_wr_addr),
        .wr_data(mux_wr_data),
        .A(acc_out), 
        .fetch(fetch), 
        .small_addr(small_addr),
        .state(state), 
        .next_state(next_state)
    );
    
    seven_segment seven_seg_display(.seg_led(seg_led), .seg_ctrl(seg_ctrl),.q(acc),.clk(clk));

endmodule
