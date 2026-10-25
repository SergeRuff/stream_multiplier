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
        logic       s_tlast;
    endclass

    class output_data_sample;
        logic [7:0] tdata;
        logic       tlast;
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
                ds.s_tfirst1 = (i< load1_size);
                ds.s_tfirst2 = (i>=load1_size);
                ds.s_tdata     = $urandom;
                ds.s_tlast     = (i == (load1_size + load2_size -1));
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
        mailbox#(input_data_sample) in1_mbx;
        mailbox#(input_data_sample) in2_mbx;

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
                if(s_tfirst1) in1_mbx.put(ds);
                if(s_tfirst2) in2_mbx.put(ds);
            end
        endtask
    endclass

    class master_driver;
        mailbox#(input_data_sample) gen2drv;

        virtual task run();
            input_data_sample ds;
            forever begin
                @(posedge clk);
                fork
                    forever begin
                        gen2drv.get(ds);
                        drive_master(ds);
                    end
                join_none
                wait(areset);
                disable fork;
                if (ds != null) begin
                    while(!ds.s_tlast && gen2drv.try_get(ds));
                    ds = null;
                end
                reset_master();
                wait(!areset);
            end
        endtask

        virtual task  reset_master();
            s_tdata <= '0;
            s_tfirst1 <= '0;
            s_tfirst2 <= '0;
        endtask

        virtual task drive_master(input input_data_sample ds);
            repeat(ds.delay) @(posedge clk);
            s_tfirst1 <= ds.s_tfirst1;
            s_tfirst2 <= ds.s_tfirst2;
            s_tdata   <= ds.s_tdata;
            @(posedge clk);
            if (ds.s_tlast) begin
                s_tfirst1 <= '0;
                s_tfirst2 <= '0;
                repeat(2) @(posedge clk);
                while(m_tvalid) @(posedge clk);
            end
        endtask
    endclass

    class master_agent;
        master_gen  master_gen;
        master_driver master_driver;
        master_monitor master_monitor;

        function new();
            master_gen = new();
            master_driver = new();
            master_monitor = new();
        endfunction

        virtual task run();
            fork
                master_gen.run();
                master_driver.run();
                master_monitor.run();
            join
        endtask
    endclass

    class slave_monitor;
        mailbox#(output_data_sample) out_mbx;
        int sample_counter = 0;

        virtual task run();
            forever begin
                wait(!areset);
                sample_counter = 0;
                fork
                    forever begin
                        monitor_slave();
                    end
                join_none
                wait(areset);
                disable fork;
            end
        endtask

        virtual task monitor_slave();
            output_data_sample ds;
            @(posedge clk);
            if(m_tvalid)    begin
                ds = new();
                ds.tdata = m_tdata;
                ds.tlast = (sample_counter==128-1);
                out_mbx.put(ds);
                sample_counter = (sample_counter==128-1)? 0 : (sample_counter + 1);
            end
        endtask
    endclass

    class slave_agent;
        slave_monitor   slave_monitor;

        function new();
            slave_monitor = new();
        endfunction

        virtual task run();
            fork
                slave_monitor.run();
            join
        endtask
    endclass

    class result_checker;
        localparam DEPTH = 128;    

        test_cfg cfg;

        bit done;

        mailbox#(input_data_sample) in1_mbx;
        mailbox#(input_data_sample) in2_mbx;
        mailbox#(output_data_sample) out_mbx;

        input_data_sample in2_reversed_queue[$];

        virtual task run();
            do_check();
        endtask

        virtual task get_reversed_mailbox_queue(
            input mailbox#(input_data_sample) mailbox_with_straight_queue,
            output input_data_sample reversed_mailbox_queue[$]
            );

            reversed_mailbox_queue.delete();

            repeat(DEPTH) begin
                input_data_sample tmp;
                mailbox_with_straight_queue.get(tmp);
                reversed_mailbox_queue.push_front(tmp);
            end
        endtask

        virtual task check(input_data_sample in1, input_data_sample in2, output_data_sample out);
            if ((in1.s_tdata*in2.s_tdata) !== out.tdata)    begin
                $error(
                    "Invalid multiplication result: Recieved: %0d, Expected: %0d * %0d = %0d",
                    out.tdata,
                    in1.s_tdata,
                    in2.s_tdata,
                    in1.s_tdata*in2.s_tdata
                    );
            end
        endtask

        virtual task do_check();
            int cnt = 0;
            input_data_sample in1_ds, in2_ds, rev_in2_ds[$];
            output_data_sample out_ds;

            forever begin
                wait(!areset);
                // wait(m_tvalid);
                fork
                    forever begin
                        if (rev_in2_ds.size() == 0) get_reversed_mailbox_queue(in2_mbx, rev_in2_ds);
                        in1_mbx.get(in1_ds);
                        in2_ds = rev_in2_ds.pop_front();
                        out_mbx.get(out_ds);

                        check(in1_ds, in2_ds, out_ds);
                        cnt = cnt + out_ds.tlast;
                        if(cnt == cfg.master_pkt_amount) break;
                    end
                    begin
                       wait(areset);
                    end
                join_any
                disable fork;
                if(cnt == cfg.master_pkt_amount)    begin
                    done = 1;
                    break;
                end
                if ((in1_mbx.num() > 0) ||
                    (in2_mbx.num() > 0) ||
                    (rev_in2_ds.size() > 0)) cnt = cnt + 1;
                while (in1_mbx.try_get(in1_ds));
                while (in2_mbx.try_get(in2_ds));
                rev_in2_ds.delete();
                while (out_mbx.try_get(out_ds));
            end
        endtask
    endclass

    class env;
        master_agent master;
        slave_agent slave;
        result_checker check;

        function new();
            master = new();
            slave  = new();
            check  = new();
        endfunction

        virtual task run();
            fork
                master.run();
                slave.run();
                check.run();
            join
        endtask
    endclass

    class test;
        test_cfg cfg;

        env env;

        mailbox#(input_data_sample)  gen2drv;
        mailbox#(input_data_sample)  in1_mbx;
        mailbox#(input_data_sample)  in2_mbx;
        mailbox#(output_data_sample) out_mbx;

        function new();
            cfg = new();
            env = new();
            gen2drv = new();
            in1_mbx  = new();
            in2_mbx  = new();
            out_mbx = new();

            env.master.master_gen.cfg = cfg;
            env.check.cfg = cfg;

            env.master.master_gen.gen2drv = gen2drv;
            env.master.master_driver.gen2drv = gen2drv;
            env.master.master_monitor.in1_mbx = in1_mbx;
            env.master.master_monitor.in2_mbx = in2_mbx;
            env.slave.slave_monitor.out_mbx = out_mbx;

            env.check.in1_mbx = in1_mbx;
            env.check.in2_mbx = in2_mbx;
            env.check.out_mbx = out_mbx;
        endfunction

        virtual task run();
            bit done;
            fork
                env.run();
                timeout();
            join_none
            wait(env.check.done);
            $display("Test was finished");
            $finish();
        endtask

        task timeout();
            repeat(cfg.test_timeout_cycles) @(posedge clk);
            $error("FAIL: Test timeout!");
            $finish();
        endtask
    endclass

    initial begin   :   main
        test test;
        test = new();
        fork
            clock_generation();
            reset();
            test.run();
        join_none
        repeat(100) @(posedge clk);
        reset();
    end :   main

endmodule
