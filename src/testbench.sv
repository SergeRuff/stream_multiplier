`timescale 1ns/1ps

module testbench;
    logic   clk;
    logic   areset;

    stream_multiplier #(
        .width(width),
        .depth(depth)
    ) DUT (
        .CLK(CLK),
        .LOAD1(LOAD1),
        .LOAD2(LOAD2),
        .RESET(RESET),
        .DIN(DIN),
        .DOUT(DOUT),
        .OE(OE)
    );

    parameter CLK_PEROID = 10;

    class data_stream;
        //
    endclass

    task reset();
        //
    endtask

    task clock_generation();
        //
    endtask

    class test_cfg;
        //
    endclass

    class master_gen;
        //
    endclass

    class master_monitor;
        //
    endclass

    class master_driver;
        //
    endclass

    class master_agent;
        //
    endclass

    class slave_monitor;
        //
    endclass

    class slave_driver;
        //
    endclass

    class slave_agent;
        //
    endclass

    class result_checker;
        //
    endclass

    class env;
        //
    endclass

    class test;
        //
    endclass

    initial begin   :   main
        //
    end :   main

endmodule