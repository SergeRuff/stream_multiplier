module oneshot_buffer
# (
    parameter width = 8,
    parameter depth = 10,
    parameter counter_width = $clog2(depth + 1),
    parameter REVERSE_BUFFER_MODE = 1'b0
)
(
    input                        clk,
    input                        rst,
    input                        push,
    input                        pop,
    input  [        width - 1:0] write_data,
    output [        width - 1:0] read_data,
    output [counter_width - 1:0] cnt,
    output                       empty,
    output                       almost_empty,
    output                       full,
    output                       almost_full,
    output                       err
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2(depth + (depth==1));
    localparam [pointer_width - 1:0] max_ptr = depth - 1;

    //------------------------------------------------------------------------

    reg [pointer_width - 1:0] wr_ptr, rd_ptr;
    reg [width - 1:0] data [0: depth - 1];
    reg [counter_width - 1:0] cnt_reg;
    reg push_reg;
    integer i;

    //------------------------------------------------------------------------

    always @(posedge clk) begin   :   push_previous_state_register
        if (rst)    push_reg <= '0;
        else        push_reg <= push;
    end

    //------------------------------------------------------------------------

    always @(posedge clk)    begin   :   write_pointer_process
        if (rst)
            wr_ptr <= '0;
        else if (push & !full)
            wr_ptr <= wr_ptr + 1'b1;
    end

    always @(posedge clk)    begin   :   read_pointer_process
        if (rst)
            rd_ptr <= REVERSE_BUFFER_MODE? max_ptr : '0;
        else if (pop & !empty & !REVERSE_BUFFER_MODE)
                rd_ptr <= rd_ptr == max_ptr ? '0 : rd_ptr + 1'b1;
        else if (pop & !empty &  REVERSE_BUFFER_MODE)
                rd_ptr <= rd_ptr == '0 ? max_ptr : rd_ptr - 1'b1;
    end

    //------------------------------------------------------------------------

    always @(posedge clk)   begin   : write_data_mux
        if (rst)
            for (i = 0; i <= max_ptr; i = i + 1)  begin
               data[i] <= '0;
            end
        else if (push & !full)
            data [wr_ptr] <= write_data;
    end

    assign read_data = data[rd_ptr];

    //------------------------------------------------------------------------

    always @ (posedge clk) begin  :   counter_process
        if (rst)
            cnt_reg <= '0;
        else if (push & !full)
            cnt_reg <= cnt_reg + 1'b1;
        else if (push_reg)
            cnt_reg <= counter_width'(depth) - counter_width'(pop);
        else if (pop & !empty)
            cnt_reg <= cnt_reg - 1'b1;
    end

    assign cnt = (push_reg & !push) ? depth : cnt_reg;

    //------------------------------------------------------------------------

    assign empty        = (cnt == 0);
    assign almost_empty = (cnt == 1);
    assign full         = (cnt == depth);
    assign almost_full  = (cnt == depth - 1);
    assign err          = (empty & pop) | (full & push);

endmodule
