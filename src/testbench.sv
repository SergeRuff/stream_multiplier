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

    class input_data_sample;
        int         delay;
        logic [0:7] s_tdata;
        logic       s_tfirst1;
        logic       s_tfirst2;
    endclass

    class output_data_sample;
        logic [7:0] tdata;
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
        int master_pkt_amount;
        // int master_load1_samples_amount;
        // int master_load2_samples_amount;
        int master_load1_samples_amount_min;
        int master_load1_samples_amount_max;
        int master_load2_samples_amount_min;
        int master_load2_samples_amount_max;
        // int master_delay;
        int master_delay_min;
        int master_delay_max;
        int test_timeout_cycles;

        function new(
            input int master_pkt_amount           = 100,
            input int master_load1_samples_amount_min   = 1,
            input int master_load1_samples_amount_max   = 150,
            input int master_load2_samples_amount_min   = 1,
            input int master_load2_samples_amount_max   = 150,
            input int master_delay_min            = 0,
            input int master_delay_max            = 10,
            input int test_timeout_cycles         = 10_000_000
        );
            string str;

            if ( master_load1_samples_amount_min > master_load1_samples_amount_max ||
                 master_load2_samples_amount_min > master_load2_samples_amount_max || 
                 master_delay_min > master_delay_max
            ) begin
                $fatal(1, "[test_cfg] Error: min value is greater than max value!");
            end

            this.master_pkt_amount = master_pkt_amount;
            this.master_load1_samples_amount_min = master_load1_samples_amount_min;
            this.master_load1_samples_amount_max = master_load1_samples_amount_max;
            this.master_load2_samples_amount_min = master_load2_samples_amount_min;
            this.master_load2_samples_amount_max = master_load2_samples_amount_max;
            this.master_delay_min = master_delay_min;
            this.master_delay_max = master_delay_max;
            this.test_timeout_cycles = test_timeout_cycles;

            // this.master_load1_samples_amount = $urandom_range(master_load1_samples_amount_max, master_load1_samples_amount_min);
            // this.master_load2_samples_amount = $urandom_range(master_load2_samples_amount_max, master_load2_samples_amount_min);
            // this.master_delay = $urandom_range(master_delay_max, master_delay_min);

            str = {str, $sformatf("master_pkt_amount        : %0d\n", master_pkt_amount         )};
            str = {str, $sformatf("master_load1_samples_amount_min: %0d\n", master_load1_samples_amount_min )};
            str = {str, $sformatf("master_load1_samples_amount_max: %0d\n", master_load1_samples_amount_max )};
            // str = {str, $sformatf("master_load1_samples_amount    : %0d\n", master_load1_samples_amount     )};
            str = {str, $sformatf("master_load2_samples_amount_min: %0d\n", master_load2_samples_amount_min )};
            str = {str, $sformatf("master_load2_samples_amount_max: %0d\n", master_load2_samples_amount_max )};
            // str = {str, $sformatf("master_load2_samples_amount    : %0d\n", master_load2_samples_amount     )};
            str = {str, $sformatf("master_delay_min         : %0d\n", master_delay_min          )};
            str = {str, $sformatf("master_delay_max         : %0d\n", master_delay_max          )};
            // str = {str, $sformatf("master_delay             : %0d\n", master_delay              )};
            str = {str, $sformatf("test_timeout_cycles      : %0d\n", test_timeout_cycles       )};
            $display(str);
        endfunction
    endclass

    class master_gen;
        test_cfg cfg;

        mailbox#(input_data_sample) gen2drv;

        virtual task run();
            repeat(cfg.master_pkt_amount)   begin
                gen_master();
            end
        endtask

        virtual task gen_master();
            input_data_sample ds;
            int load1_size, load2_size;
            int delay;
            load1_size = $urandom_range(cfg.master_load1_samples_amount_max, cfg.master_load1_samples_amount_min);
            load2_size = $urandom_range(cfg.master_load2_samples_amount_max, cfg.master_load2_samples_amount_min);
            delay = $urandom_range(cfg.master_delay_max, cfg.master_delay_min);

            for (int i = 0; i < (load1_size+load2_size); i++)  begin
                ds = create_sample();
                if (i == 0) ds.delay = delay;
                else        ds.delay = 0;
                ds.s_tfirst1 = (i==0);
                ds.s_tfirst2 = (i==load1_size);
                ds.s_tdata     = $urandom;
                gen2drv.put(ds);
            end
        endtask

        virtual function input_data_sample create_sample();
            input_data_sample ds;
            ds = new();
            return ds;
        endfunction
    endclass

    class master_monitor;
        mailbox#(input_data_sample) in_mbx;

        virtual task run();
            forever begin
                wait(!areset);
                fork
                    forever begin
                        m_monitor();
                    end
                join_none
                wait(areset);
                disable fork;
            end
        endtask

        virtual task m_monitor();
            input_data_sample ds;
            @(posedge clk);
            if (s_tfirst1 | s_tfirst2)   begin
                ds = new();
                ds.s_tdata = s_tdata;
                ds.delay = '0;
                ds.s_tfirst1 = s_tfirst1;
                ds.s_tfirst2 = s_tfirst2;
                in_mbx.put(ds);
            end
        endtask
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