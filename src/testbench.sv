`timescale 1ns/1ps

module testbench;
    logic       clk;
    logic       areset;

    logic       s_tfirst1;
    logic       s_tfirst2;
    logic [0:7] s_tdata;

    logic       m_tvalid;
    logic [7:0] m_tdata;

    stream_multiplier #(
        .width(8),
        .depth(128)
    ) DUT (
        .CLK    (clk),
        .LOAD1  (s_tfirst1),
        .LOAD2  (s_tfirst2),
        .RESET  (areset),
        .DIN    (s_tdata),
        .DOUT   (m_tdata),
        .OE     (m_tvalid)
    );

    parameter CLK_PEROID = 10;

    class data_stream;
        int         delay;
        logic [7:0] tdata;
        logic       s_tfirst1;
        logic       s_tfirst2;
    endclass

    task reset();
        areset <= 1;
        #(CLK_PEROID);
        areset <= 0;
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