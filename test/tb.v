`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

module tb_lipsi_processor;

    // Testbench inputs
    reg clk;
    reg reset;
    reg [3:0] N;

    // Testbench outputs
    wire [7:0] acc;
    wire [3:0] seg_ctrl;
    wire [7:0] seg_led;

    // Instantiate the processor
    tt_um_lipsi_processor_shiva uut (
        .clk(clk),
        .reset(reset),
        .N(N),
        .acc(acc),
        .seg_ctrl(seg_ctrl),
        .seg_led(seg_led)
    );

    // Clock generation: 10 ns period
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Apply reset and test multiple input values
    initial begin
       $dumpfile("tt_um_lipsi_processor.vcd");
        $dumpvars(0, tb_lipsi_processor);

        // Test 1: N = 5
        reset = 1'b1;
        N = 4'd5;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // Wait for processor execution
        repeat (500) @(posedge clk);
        #1;
        $display("N = %0d, Accumulator = %0d", N, acc);

        // Test 2: N = 7
        @(negedge clk);
        reset = 1'b1;
        N = 4'd7;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (500) @(posedge clk);
        #1;
        $display("N = %0d, Accumulator = %0d", N, acc);

        // Test 3: N = 10
        @(negedge clk);
        reset = 1'b1;
        N = 4'd10;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        repeat (500) @(posedge clk);
        #1;
        $display("N = %0d, Accumulator = %0d", N, acc);

        $finish;
    end

    // Monitor processor outputs
    initial begin
        $monitor(
            "Time=%0t | Reset=%b | N=%0d | ACC=%0d | SEG_CTRL=%b | SEG_LED=%b",
            $time, reset, N, acc, seg_ctrl, seg_led
        );
    end

endmodule
```
