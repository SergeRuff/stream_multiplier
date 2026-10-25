module oneshot_buffer
# (
    parameter width = 8,
    parameter depth = 10,
    parameter counter_width = $clog2 (depth + 1),
    parameter REVERSE_BUFFER_MODE = 1'b0
)
(
    input                              clk,
    input                              rst,
    input                              push,
    input                              pop,
    input  logic [        width - 1:0] write_data,
    output logic [        width - 1:0] read_data,
    output logic [counter_width - 1:0] cnt,
    output logic                       empty,
    output logic                       full,
    output logic                       err
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth + (depth==1));

    localparam max_ptr = pointer_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr, rd_ptr;

    logic [width - 1:0] data [0: depth - 1];

    logic [counter_width - 1:0] cnt_reg;

    logic push_reg;

    //------------------------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin   :   push_previous_state_register
        if (rst)    push_reg <= '0;
        else        push_reg <= push;
    end : push_previous_state_register

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)    begin   :   write_pointer_process
        if (rst)
            wr_ptr <= '0;
        else if (push & !full)
            wr_ptr <= wr_ptr + 1'b1;
    end :   write_pointer_process

    always_ff @ (posedge clk or posedge rst)    begin   :   read_pointer_process
        if (rst)
            rd_ptr <= REVERSE_BUFFER_MODE? max_ptr : '0;
        else if (pop & !empty & !REVERSE_BUFFER_MODE)
                rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
        else if (pop & !empty &  REVERSE_BUFFER_MODE)
                rd_ptr <= rd_ptr == '0 ? max_ptr : rd_ptr - 1'b1;
    end :   read_pointer_process

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)   begin   : write_data_mux
        if (rst)
            for (int i = 0; i <= max_ptr; i++)  begin
               data[i] <= '0;
            end
        else if (push & !full)
            data [wr_ptr] <= write_data;
    end :   write_data_mux

    always_comb begin   :   read_data_mux
        read_data = data[rd_ptr];
    end :   read_data_mux

    // assign read_data = data [rd_ptr];

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst) begin  :   counter_process
        if (rst)
            cnt_reg <= '0;
        else if (push & !full)
            cnt_reg <= cnt_reg + 1'b1;
        else if (push_reg)
            cnt_reg <= counter_width'(depth) - counter_width'(pop);
        else if (pop & !empty)
            cnt_reg <= cnt_reg - 1'b1;
    end :   counter_process

    always_comb begin   : counter_output_hack
        cnt = (push_reg & !push)? counter_width'(depth) : cnt_reg;
    end :   counter_output_hack


    //------------------------------------------------------------------------

    always_comb begin   :   empty_flag_process
        empty = (cnt == '0);
    end :   empty_flag_process

    always_comb begin   :   full_flag_process
        full = (cnt == counter_width'(depth));
    end :   full_flag_process

    always_comb begin   :   error_flag_process
        err = (empty & pop) | (full & push);
    end :   error_flag_process

    // assign empty = (cnt == '0);  // Same as "~| cnt"
    // assign full = (cnt == counter_width' (depth));

endmodule
