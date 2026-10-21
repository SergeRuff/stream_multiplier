module stream_multiplier
# (
    parameter width = 8,
    parameter depth = 10
)
(
                            input                CLK,
                            input                LOAD1,
                            input                LOAD2,
                            input                RESET,
                            input  [0:width - 1] DIN,

                            output [width - 1:0] DOUT,
                            output               OE
                        );

    localparam counter_width = $clog2(depth + 1);

    logic buffer1_push;
    logic buffer1_pop;
    logic buffer1_full_flag;
    logic buffer1_empty_flag;
    logic [counter_width - 1: 0] buffer1_counter;
    logic [width - 1:0] buffer1_data_out;

    logic buffer2_push;
    logic buffer2_pop;
    logic buffer2_full_flag;
    logic buffer2_empty_flag;
    logic [counter_width - 1: 0] buffer2_counter;
    logic [width - 1:0] buffer2_data_out;

    logic err;

    typedef enum logic [2:0]    {
        ST_IDLE,
        ST_LOAD1,
        ST_LOAD2,
        ST_UPLOAD_RESULT,
        ST_ERROR
    }   states_e;

    states_e current_state, next_state;

    flip_flop_circle_buffer #(
        .width(width),
        .depth(depth)
    ) buffer1 (
        .clk(CLK),
        .rst(RESET),
        .push(buffer1_push),
        .pop(buffer1_pop),
        .write_data(DIN),
        .read_data(buffer1_data_out),
        .cnt(buffer1_counter),
        .empty(buffer1_empty_flag),
        .full(buffer1_full_flag)
    );

    flip_flop_circle_buffer #(
        .width(width),
        .depth(depth)
    ) buffer2 (
        .clk(CLK),
        .rst(RESET),
        .push(buffer2_push),
        .pop(buffer2_pop),
        .write_data(DIN),
        .read_data(buffer2_data_out),
        .cnt(buffer2_counter),
        .empty(buffer2_empty_flag),
        .full(buffer2_full_flag)
    );

endmodule