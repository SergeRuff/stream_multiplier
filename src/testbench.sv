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
        clk <= 0;
        forever begin
            #(CLK_PEROID/2) clk <= ~clk;
        end
    endtask

    class test_cfg;
        int master_samples_amount;
        int master_samples_amount_min;
        int master_samples_amount_max;
        int master_delay;
        int master_delay_min;
        int master_delay_max;
        int test_timeout_cycles;

        function new(
            input int master_samples_amount_min   = 1,
            input int master_samples_amount_max   = 150,
            input int master_delay_min            = 0,
            input int master_delay_max            = 10,
            input int test_timeout_cycles       = 10_000_000
        );
            string str;

            if (master_samples_amount_min > master_samples_amount_max || master_delay_min > master_delay_max) begin
                $fatal(1, "[test_cfg] Error: min value is greater than max value!");
            end

            this.master_samples_amount_min = master_samples_amount_min;
            this.master_samples_amount_max = master_samples_amount_max;
            this.master_delay_min = master_delay_min;
            this.master_delay_max = master_delay_max;
            this.test_timeout_cycles = test_timeout_cycles;

            this.master_samples_amount = $urandom_range(master_samples_amount_max, master_samples_amount_min);
            this.master_delay = $urandom_range(master_delay_max, master_delay_min);

            str = {str, $sformatf("master_samples_amount_min    : %0d\n", master_samples_amount_min    )};
            str = {str, $sformatf("master_samples_amount_max    : %0d\n", master_samples_amount_max    )};
            str = {str, $sformatf("master_samples_amount        : %0d\n", master_samples_amount        )};
            str = {str, $sformatf("master_delay_min   : %0d\n", master_delay_min   )};
            str = {str, $sformatf("master_delay_max   : %0d\n", master_delay_max   )};
            str = {str, $sformatf("master_delay       : %0d\n", master_delay       )};
            str = {str, $sformatf("test_timeout_cycles: %0d\n", test_timeout_cycles)};
            $display(str);
        endfunction
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